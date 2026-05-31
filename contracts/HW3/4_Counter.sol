// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Counter
 * @dev Контракт-лічильник із функціями збільшення, зменшення та отримання значення
 */
contract Counter {
    uint256 private count;

    event Incremented(uint256 newValue);
    event Decremented(uint256 newValue);

    /// @notice Збільшити лічильник на 1
    function increment() public {
        count++;
        emit Incremented(count);
    }

    /// @notice Зменшити лічильник на 1 (не може бути від'ємним)
    function decrement() public {
        require(count > 0, "Counter: cannot go below zero");
        count--;
        emit Decremented(count);
    }

    /// @notice Отримати поточне значення лічильника
    /// @return Поточне значення count
    function getCount() public view returns (uint256) {
        return count;
    }
}
