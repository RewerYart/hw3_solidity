// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title TaskList
 * @dev Управління списком задач: додавання, видалення, перегляд
 */
contract TaskList {
    string[] private tasks;

    event TaskAdded(uint256 index, string task);
    event TaskRemoved(uint256 index);

    /// @notice Додати нову задачу
    /// @param task Текст задачі
    function addTask(string memory task) public {
        require(bytes(task).length > 0, "TaskList: task cannot be empty");
        tasks.push(task);
        emit TaskAdded(tasks.length - 1, task);
    }

    /// @notice Видалити задачу за індексом (swap-and-pop, порядок не зберігається)
    /// @param index Індекс задачі у масиві
    function removeTask(uint256 index) public {
        require(index < tasks.length, "TaskList: invalid index");
        emit TaskRemoved(index);
        tasks[index] = tasks[tasks.length - 1];
        tasks.pop();
    }

    /// @notice Отримати всі задачі
    /// @return Масив рядків із задачами
    function getTasks() public view returns (string[] memory) {
        return tasks;
    }
}
