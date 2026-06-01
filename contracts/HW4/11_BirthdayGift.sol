// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title BirthdayGift
 * @dev Бабуся вносить ETH, який ділиться порівну між онуками.
 *      Онуки додаються по одному через addGrandchild() з людиночитаємою датою.
 *      Кожен онук може зняти свою частку у день народження або після нього.
 */
contract BirthdayGift {
    address public owner;
    uint256 public totalDeposited;
    bool public deposited;

    struct Grandchild {
        address addr;
        uint256 birthdayTimestamp;
        bool withdrawn;
    }

    Grandchild[] public grandchildren;
    // addr → індекс у масиві + 1 (0 означає "не онук")
    mapping(address => uint256) private grandchildIndex;

    event GrandchildAdded(
        address indexed grandchild,
        uint16 year,
        uint8 month,
        uint8 day,
        uint256 birthdayTimestamp
    );
    event Deposited(address indexed owner, uint256 amount, uint256 sharePerGrandchild);
    event Withdrawn(address indexed grandchild, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "BirthdayGift: caller is not owner");
        _;
    }

    modifier onlyGrandchild() {
        require(grandchildIndex[msg.sender] != 0, "BirthdayGift: caller is not a grandchild");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Конвертує людиночитаєму дату у Unix-timestamp
    /// @dev Алгоритм BokkyPooBah — перевірений стандарт для Solidity
    /// @param year  Рік (наприклад 2025)
    /// @param month Місяць 1–12
    /// @param day   День 1–31
    /// @return Unix-timestamp о опівночі UTC для вказаної дати
    function dateToTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) public pure returns (uint256) {
        require(year >= 1970, "BirthdayGift: year must be >= 1970");
        require(month >= 1 && month <= 12, "BirthdayGift: invalid month");
        require(day >= 1 && day <= 31, "BirthdayGift: invalid day");

        int256 y = int256(uint256(year));
        int256 m = int256(uint256(month));
        int256 d = int256(uint256(day));

        int256 days_ = d
            - 32075
            + (1461 * (y + 4800 + (m - 14) / 12)) / 4
            + (367 * (m - 2 - ((m - 14) / 12) * 12)) / 12
            - (3 * ((y + 4900 + (m - 14) / 12) / 100)) / 4
            - 2440588;

        return uint256(days_) * 86400;
    }

    /// @notice Додати онука з датою дня народження (тільки власник, до депозиту)
    /// @param grandchild Адреса онука
    /// @param year  Рік дня народження (наприклад 2025)
    /// @param month Місяць 1–12
    /// @param day   День 1–31
    function addGrandchild(
        address grandchild,
        uint16 year,
        uint8 month,
        uint8 day
    ) external onlyOwner {
        require(!deposited, "BirthdayGift: cannot add grandchild after deposit");
        require(grandchild != address(0), "BirthdayGift: zero address");
        require(grandchildIndex[grandchild] == 0, "BirthdayGift: already added");

        uint256 ts = dateToTimestamp(year, month, day);
        grandchildren.push(Grandchild({addr: grandchild, birthdayTimestamp: ts, withdrawn: false}));
        grandchildIndex[grandchild] = grandchildren.length;
        emit GrandchildAdded(grandchild, year, month, day, ts);
    }

    /// @notice Бабуся вносить ETH (лише один раз, після додавання всіх онуків)
    function deposit() external payable onlyOwner {
        require(!deposited, "BirthdayGift: already deposited");
        require(grandchildren.length > 0, "BirthdayGift: no grandchildren added yet");
        require(msg.value > 0, "BirthdayGift: deposit amount must be greater than zero");
        require(msg.value >= grandchildren.length, "BirthdayGift: deposit too small to split");

        totalDeposited = msg.value;
        deposited = true;
        uint256 share = msg.value / grandchildren.length;
        emit Deposited(msg.sender, msg.value, share);
    }

    /// @notice Онук знімає свою частку (доступно з дня народження)
    function withdraw() external onlyGrandchild {
        require(deposited, "BirthdayGift: no funds deposited yet");
        uint256 idx = grandchildIndex[msg.sender] - 1;
        Grandchild storage gc = grandchildren[idx];
        require(block.timestamp >= gc.birthdayTimestamp, "BirthdayGift: birthday has not come yet");
        require(!gc.withdrawn, "BirthdayGift: gift already withdrawn");

        gc.withdrawn = true; // CEI: ефекти до взаємодії
        uint256 share = totalDeposited / grandchildren.length;
        emit Withdrawn(msg.sender, share);
        payable(msg.sender).transfer(share);
    }

    /// @notice Перевірити чи може онук зняти подарунок прямо зараз
    function canWithdraw(address grandchild) external view returns (bool) {
        uint256 idx = grandchildIndex[grandchild];
        if (idx == 0) return false;
        Grandchild storage gc = grandchildren[idx - 1];
        return deposited && !gc.withdrawn && block.timestamp >= gc.birthdayTimestamp;
    }

    /// @notice Скільки днів залишилось до дня народження (0 якщо вже настав)
    function daysUntilBirthday(address grandchild) external view returns (uint256) {
        uint256 idx = grandchildIndex[grandchild];
        require(idx != 0, "BirthdayGift: not a grandchild");
        uint256 birthday = grandchildren[idx - 1].birthdayTimestamp;
        if (block.timestamp >= birthday) return 0;
        return (birthday - block.timestamp) / 86400;
    }

    /// @notice Розмір частки для кожного онука у wei
    function getShare() external view returns (uint256) {
        if (grandchildren.length == 0) return 0;
        return totalDeposited / grandchildren.length;
    }

    /// @notice Список усіх онуків
    function getGrandchildren() external view returns (Grandchild[] memory) {
        return grandchildren;
    }
}
