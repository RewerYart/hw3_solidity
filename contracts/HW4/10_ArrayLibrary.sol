// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title ArrayLibrary
 * @dev Бібліотека корисних функцій для масивів uint256
 */
library ArrayLibrary {
    /// @notice Знайти індекс першого входження значення
    /// @return Індекс або -1 якщо не знайдено
    function indexOf(uint256[] storage arr, uint256 value) internal view returns (int256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                return int256(i);
            }
        }
        return -1;
    }

    /// @notice Перевірити чи містить масив значення
    function contains(uint256[] storage arr, uint256 value) internal view returns (bool) {
        return indexOf(arr, value) != -1;
    }

    /// @notice Видалити елемент за індексом (swap-and-pop, не зберігає порядок)
    function removeByIndex(uint256[] storage arr, uint256 index) internal {
        require(index < arr.length, "ArrayLibrary: index out of bounds");
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }

    /// @notice Видалити перше входження значення
    function removeByValue(uint256[] storage arr, uint256 value) internal {
        int256 idx = indexOf(arr, value);
        require(idx >= 0, "ArrayLibrary: value not found");
        removeByIndex(arr, uint256(idx));
    }

    /// @notice Сортування бульбашкою за зростанням
    /// @dev Використовується лише для невеликих масивів — O(n^2) по газу
    function bubbleSort(uint256[] storage arr) internal {
        uint256 n = arr.length;
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (arr[j] > arr[j + 1]) {
                    uint256 temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
        }
    }
}

/**
 * @title ArrayUtils
 * @dev Контракт для роботи з масивом через бібліотеку ArrayLibrary
 */
contract ArrayUtils {
    using ArrayLibrary for uint256[];

    uint256[] private items;

    /// @notice Додати елемент до масиву
    function add(uint256 value) public {
        items.push(value);
    }

    /// @notice Видалити перше входження значення з масиву
    function remove(uint256 value) public {
        items.removeByValue(value);
    }

    /// @notice Відсортувати масив за зростанням
    function sort() public {
        items.bubbleSort();
    }

    /// @notice Знайти індекс значення (-1 якщо не знайдено)
    function find(uint256 value) public view returns (int256) {
        return items.indexOf(value);
    }

    /// @notice Отримати весь масив
    function getAll() public view returns (uint256[] memory) {
        return items;
    }
}
