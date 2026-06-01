// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title EmergencyFund
 * @dev Фонд для надзвичайних ситуацій (наприклад, медичних потреб).
 *      Учасники щомісяця вносять ETH. Для виплати потрібно N підтверджень
 *      від інших учасників (multisig).
 */
contract EmergencyFund {
    address public owner;
    uint256 public requiredConfirmations;
    uint256 public monthlyContribution;

    struct Participant {
        bool isActive;
        uint256 totalContributed;
        uint256 lastContribution; // timestamp останнього внеску
    }

    struct EmergencyRequest {
        address requester;
        uint256 amount;
        string reason;
        uint256 confirmationsCount;
        bool executed;
        bool exists;
    }

    mapping(address => Participant) public participants;
    address[] public participantList;
    uint256 public participantCount;

    mapping(uint256 => EmergencyRequest) public requests;
    uint256 public requestCount;

    // Підтвердження: requestId → адреса → чи підтвердив
    mapping(uint256 => mapping(address => bool)) public hasConfirmed;

    event ParticipantJoined(address indexed participant);
    event FundsContributed(address indexed participant, uint256 amount);
    event EmergencyRequested(
        uint256 indexed requestId,
        address indexed requester,
        uint256 amount,
        string reason
    );
    event RequestConfirmed(
        uint256 indexed requestId,
        address indexed confirmer,
        uint256 confirmationsCount
    );
    event EmergencyExecuted(
        uint256 indexed requestId,
        address indexed recipient,
        uint256 amount
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "EmergencyFund: caller is not owner");
        _;
    }

    modifier onlyParticipant() {
        require(participants[msg.sender].isActive, "EmergencyFund: caller is not a participant");
        _;
    }

    /// @param _requiredConfirmations Кількість підтверджень для виплати
    /// @param _monthlyContribution Мінімальний внесок у wei
    constructor(uint256 _requiredConfirmations, uint256 _monthlyContribution) {
        require(_requiredConfirmations > 0, "EmergencyFund: confirmations must be > 0");
        require(_monthlyContribution > 0, "EmergencyFund: contribution must be > 0");
        owner = msg.sender;
        requiredConfirmations = _requiredConfirmations;
        monthlyContribution = _monthlyContribution;
    }

    /// @notice Власник додає учасника фонду
    function addParticipant(address participant) external onlyOwner {
        require(participant != address(0), "EmergencyFund: zero address");
        require(!participants[participant].isActive, "EmergencyFund: already a participant");
        participants[participant] = Participant({
            isActive: true,
            totalContributed: 0,
            lastContribution: 0
        });
        participantList.push(participant);
        participantCount++;
        emit ParticipantJoined(participant);
    }

    /// @notice Учасник вносить ETH до фонду
    function contribute() external payable onlyParticipant {
        require(
            msg.value >= monthlyContribution,
            "EmergencyFund: amount below monthly contribution"
        );
        participants[msg.sender].totalContributed += msg.value;
        participants[msg.sender].lastContribution = block.timestamp;
        emit FundsContributed(msg.sender, msg.value);
    }

    /// @notice Учасник подає заявку на екстрену виплату
    /// @return requestId Ідентифікатор заявки
    function requestEmergency(
        uint256 amount,
        string calldata reason
    ) external onlyParticipant returns (uint256) {
        require(amount > 0, "EmergencyFund: amount must be greater than zero");
        require(
            amount <= address(this).balance,
            "EmergencyFund: insufficient contract balance"
        );
        uint256 requestId = requestCount;
        requests[requestId] = EmergencyRequest({
            requester: msg.sender,
            amount: amount,
            reason: reason,
            confirmationsCount: 0,
            executed: false,
            exists: true
        });
        requestCount++;
        emit EmergencyRequested(requestId, msg.sender, amount, reason);
        return requestId;
    }

    /// @notice Учасник підтверджує заявку (не може підтверджувати свою)
    function confirmRequest(uint256 requestId) external onlyParticipant {
        require(requests[requestId].exists, "EmergencyFund: request does not exist");
        require(!requests[requestId].executed, "EmergencyFund: request already executed");
        require(
            msg.sender != requests[requestId].requester,
            "EmergencyFund: cannot confirm own request"
        );
        require(
            !hasConfirmed[requestId][msg.sender],
            "EmergencyFund: already confirmed"
        );
        hasConfirmed[requestId][msg.sender] = true;
        requests[requestId].confirmationsCount++;
        emit RequestConfirmed(requestId, msg.sender, requests[requestId].confirmationsCount);
    }

    /// @notice Виконати виплату після набору достатньої кількості підтверджень
    function executeRequest(uint256 requestId) external onlyParticipant {
        EmergencyRequest storage req = requests[requestId];
        require(req.exists, "EmergencyFund: request does not exist");
        require(!req.executed, "EmergencyFund: request already executed");
        require(
            req.confirmationsCount >= requiredConfirmations,
            "EmergencyFund: not enough confirmations"
        );
        require(address(this).balance >= req.amount, "EmergencyFund: insufficient balance");

        req.executed = true; // CEI: ефекти до взаємодії
        emit EmergencyExecuted(requestId, req.requester, req.amount);
        payable(req.requester).transfer(req.amount);
    }

    /// @notice Баланс фонду
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Інформація про заявку
    function getRequest(uint256 requestId) external view returns (EmergencyRequest memory) {
        return requests[requestId];
    }

    /// @notice Перевірити чи є адреса учасником
    function isParticipant(address addr) external view returns (bool) {
        return participants[addr].isActive;
    }
}
