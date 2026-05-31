// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title ProductStore
 * @dev Магазин товарів: додавання, купівля з перевіркою балансу, перегляд
 */
contract ProductStore {
    struct Product {
        string name;
        uint256 price;
    }

    Product[] private products;

    event ProductAdded(uint256 index, string name, uint256 price);
    event ProductPurchased(uint256 index, address buyer, uint256 paid);

    /// @notice Додати новий товар
    /// @param name Назва товару
    /// @param price Ціна у wei
    function addProduct(string memory name, uint256 price) public {
        require(bytes(name).length > 0, "ProductStore: name cannot be empty");
        require(price > 0, "ProductStore: price must be greater than zero");
        products.push(Product(name, price));
        emit ProductAdded(products.length - 1, name, price);
    }

    /// @notice Купити товар, надіславши ETH
    /// @param index Індекс товару у масиві
    function buyProduct(uint256 index) public payable {
        require(index < products.length, "ProductStore: invalid product index");
        uint256 price = products[index].price;
        require(msg.value >= price, "ProductStore: insufficient funds");

        emit ProductPurchased(index, msg.sender, msg.value);

        // Повернення залишку покупцю
        uint256 refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    /// @notice Отримати список усіх товарів
    /// @return Масив структур Product
    function getProducts() public view returns (Product[] memory) {
        return products;
    }
}
