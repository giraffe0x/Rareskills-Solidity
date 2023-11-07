- Why does the `price0CumulativeLast` and `price1CumulativeLast` never decrement?

The reason these variables never decrement is because they are designed to keep a running total of the prices, not the current price. Even if the price of a token decreases, the cumulative price will still increase, because it's a sum of all the prices up to that point in time.

This design allows the TWAP to be calculated over any period of time by subtracting the cumulative price at the start of the period from the cumulative price at the end of the period. If the cumulative price were allowed to decrease, it would not be possible to accurately calculate the TWAP over periods of time when the price decreased.

- How do you write a contract that uses the oracle?

1. Decide if data freshness OR resistance to price manipulation is more important
2. Fixed window oracle
    - Read from Uniswap pair and store the cumulative price and timestamp once per period
    - Compute average price over each data point
    - compute the 24h-average price as (price0CumulativeLast() - price0CumulativeOld) / (block.timestamp - timestampOld)
3. Moving average oracle
    - Determine window size + granularity (no. of updates within each window)
    - Average computed for current window, higher the granularity, the more precise the average will be


- Why are `price0CumulativeLast` and `price1CumulativeLast` stored separately? Why not just calculate ``price1CumulativeLast = 1/price0CumulativeLast`?

Prices can be read either way, price of token0 in token1 and vice versa
Time-weight price of using either token0 or token1 can be different, so uniswap offers both
