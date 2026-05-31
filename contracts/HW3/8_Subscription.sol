// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Subscription
 * @dev Система підписок: оплата доступу, перевірка активності, адмін-управління ціною
 */
contract Subscription {
    address private admin;
    uint256 public subscriptionPrice;
    uint256 public constant DURATION = 30 days;

    mapping(address => uint256) public subscriptionExpiry;

    event Subscribed(address user, uint256 expiry);
    event PriceChanged(uint256 oldPrice, uint256 newPrice);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Subscription: caller is not admin");
        _;
    }

    /// @notice Ініціалізація контракту з початковою ціною підписки
    /// @param initialPrice Ціна підписки у wei
    constructor(uint256 initialPrice) {
        require(initialPrice > 0, "Subscription: price must be greater than zero");
        admin = msg.sender;
        subscriptionPrice = initialPrice;
    }

    /// @notice Оплатити підписку на 30 днів
    function subscribe() public payable {
        require(msg.value >= subscriptionPrice, "Subscription: insufficient funds");

        if (subscriptionExpiry[msg.sender] > block.timestamp) {
            subscriptionExpiry[msg.sender] += DURATION;
        } else {
            subscriptionExpiry[msg.sender] = block.timestamp + DURATION;
        }

        emit Subscribed(msg.sender, subscriptionExpiry[msg.sender]);

        // Повернення залишку
        uint256 refund = msg.value - subscriptionPrice;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    /// @notice Перевірити, чи активна підписка користувача
    /// @param user Адреса користувача
    /// @return true якщо підписка активна
    function isSubscribed(address user) public view returns (bool) {
        return subscriptionExpiry[user] > block.timestamp;
    }

    /// @notice Змінити вартість підписки (тільки адмін)
    /// @param newPrice Нова ціна у wei
    function setPrice(uint256 newPrice) public onlyAdmin {
        require(newPrice > 0, "Subscription: price must be greater than zero");
        emit PriceChanged(subscriptionPrice, newPrice);
        subscriptionPrice = newPrice;
    }
}
