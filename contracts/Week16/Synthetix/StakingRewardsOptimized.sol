// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/Utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Inheritance
import "./IStakingRewardsOptimized.sol";
import "./RewardsDistributionRecipient.sol";
import "./Pausable.sol";

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract StakingRewardsOptimized is IStakingRewardsOptimized, RewardsDistributionRecipient, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    //@audit changed tokens to immutable
    IERC20 public immutable rewardsToken;
    IERC20 public immutable stakingToken;

    //@audit changed time variables to uint32
    uint32 public periodFinish;
    uint32 public rewardsDuration = 7 days;
    uint32 public lastUpdateTime;

    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public totalSupply;
    mapping(address => uint256) private _balances;

    //@audit added
    uint256 constant MULTIPLIER = 1e18;

    /* ========== CONSTRUCTOR ========== */

    //@audit marked payable to save gas
    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) payable Owned(_owner) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256, uint256 _totalSupply) {
        //@audit stored TS in memory
        _totalSupply = totalSupply;
        //@audit handle non-zero case first
        if (_totalSupply != 0) {
          return
            (rewardPerTokenStored + (
                lastTimeRewardApplicable() - (lastUpdateTime) * (rewardRate) * (MULTIPLIER) / (_totalSupply)
            ), _totalSupply);
        } else {
            return (rewardPerTokenStored, 0);
        }
    }

    function earned(address account) public view returns (uint256) {
        (uint256 _rewardPerToken,) = rewardPerToken();
        return _balances[account] * (_rewardPerToken - (userRewardPerTokenPaid[account])) / (MULTIPLIER) + (rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * (rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant notPaused  {
        uint256 _totalSupply = updateReward(msg.sender);
        require(amount > 0, "Cannot stake 0");
        unchecked {
            totalSupply = _totalSupply + (amount);
            _balances[msg.sender] = _balances[msg.sender] + (amount);
        }
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        uint256 _totalSupply = updateReward(msg.sender);
        require(amount > 0, "Cannot withdraw 0");
        unchecked{
            totalSupply = _totalSupply - (amount);
        }
        //@audit need to underflow if amount more than caller's balance
        _balances[msg.sender] = _balances[msg.sender] - (amount);

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            //@audit delete instead of setting to 0
            delete rewards[msg.sender];
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution {
        updateReward(msg.sender);
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / (rewardsDuration);
        } else {
          unchecked{
              uint256 remaining = periodFinish - (block.timestamp);
              uint256 leftover = remaining * (rewardRate);
              rewardRate = reward + (leftover) / (rewardsDuration);
          }
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance / (rewardsDuration), "Provided reward too high");

        lastUpdateTime = uint32(block.timestamp);
        periodFinish = uint32(block.timestamp + (rewardsDuration));
        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = uint32(_rewardsDuration);
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== MODIFIERS ========== */

    //@audit changed from modifier to to private function, returns totalSupply which can be reused
    function updateReward(address account) private returns (uint256) {
        (uint256 _rewardPerTokenStored, uint256 _totalSupply) = rewardPerToken();
        rewardPerTokenStored = _rewardPerTokenStored;

        lastUpdateTime = uint32(lastTimeRewardApplicable());
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = _rewardPerTokenStored;
        }

        return _totalSupply;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
