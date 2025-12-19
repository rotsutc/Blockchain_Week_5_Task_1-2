// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Hệ thống bỏ phiếu an toàn (Secure Voting System)
/// @notice Bao gồm: RBAC, Time-Lock, Circuit Breaker, Extend Time, Winner Algorithm
contract SecureVoting {

    // --- STRUCTS & STATE ---
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    Candidate[] public candidates;
    mapping(address => bool) public hasVoted;
    
    address public electionOfficial; 
    uint public votingStart;
    uint public votingEnd; 
    bool public emergencyStop; 

    // --- EVENTS ---
    event CandidateAdded(uint id, string name);
    event VoteCast(address indexed voter, uint candidateId);
    event VotingExtended(uint newEndTime);
    event EmergencyStopToggled(bool status);

    // --- MODIFIERS ---
    modifier onlyOfficial() {
        require(msg.sender == electionOfficial, "Error: Only Official allowed");
        _;
    }

    modifier activeVoting() {
        require(block.timestamp >= votingStart, "Error: Voting not started");
        require(block.timestamp <= votingEnd, "Error: Voting ended");
        require(!emergencyStop, "Error: Voting is stopped");
        _;
    }

    constructor(uint _durationInMinutes) {
        electionOfficial = msg.sender;
        votingStart = block.timestamp;
        votingEnd = block.timestamp + (_durationInMinutes * 1 minutes);
    }

    // --- CORE FUNCTIONS ---

    function addCandidate(string memory _name) public onlyOfficial {
        uint id = candidates.length;
        candidates.push(Candidate(id, _name, 0));
        emit CandidateAdded(id, _name);
    }

    function vote(uint _candidateId) public activeVoting {
        require(!hasVoted[msg.sender], "Error: You have already voted");
        require(_candidateId < candidates.length, "Error: Invalid ID");

        hasVoted[msg.sender] = true; 
        candidates[_candidateId].voteCount++; 

        emit VoteCast(msg.sender, _candidateId);
    }

    // --- TÍNH NĂNG SÁNG TẠO (CREATIVE FEATURES) ---

    /// @notice 1. Emergency Stop (Đã có)
    function toggleEmergencyStop() public onlyOfficial {
        emergencyStop = !emergencyStop;
        emit EmergencyStopToggled(emergencyStop);
    }

    /// @notice 2. Extend Voting Time (Mới bổ sung)
    /// @dev Cho phép Admin gia hạn thêm phút nếu cần
    function extendVoting(uint _extraMinutes) public onlyOfficial {
        votingEnd += (_extraMinutes * 1 minutes);
        emit VotingExtended(votingEnd);
    }

    /// @notice 3. Get Winner Algorithm (Mới bổ sung)
    /// @dev Thuật toán tìm Max trong mảng để tự động công bố người thắng
    function getWinner() public view returns (string memory winnerName, uint maxVotes) {
        require(candidates.length > 0, "No candidates");

        uint winningVoteCount = 0;
        uint winningIndex = 0;

        // Thuật toán: Duyệt mảng tìm số lớn nhất
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningIndex = i;
            }
        }
        
        // Trả về kết quả
        return (candidates[winningIndex].name, winningVoteCount);
    }
    
    // Hàm hỗ trợ lấy danh sách (cho Frontend/Test)
    function getCandidate(uint _candidateId) public view returns (Candidate memory) {
        return candidates[_candidateId];
    }
}