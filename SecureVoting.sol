// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecureVoting {
    // 1. STRUCTS: Candidate (id, voteCount) 
    struct Candidate {
        uint256 id;
        uint256 voteCount;
        string name; // Thêm name để dễ nhận diện (tùy chọn)
    }

    // STATE VARIABLES
    address public electionOfficial; // Người quản lý bầu cử
    
    // Lưu trữ danh sách ứng cử viên
    // Mapping từ ID ứng cử viên -> thông tin Candidate
    mapping(uint256 => Candidate) public candidates;
    uint256 public candidatesCount;

    // 4. ONE-PERSON-ONE-VOTE: Mapping hasVoted 
    mapping(address => bool) public hasVoted;

    // 3. TIME-LOCK: Thời gian bắt đầu và kết thúc 
    uint256 public votingStart;
    uint256 public votingEnd;

    // Constructor: Thiết lập quyền Official và thời gian bỏ phiếu
    constructor(uint256 _durationInMinutes) {
        electionOfficial = msg.sender; // Người deploy contract là Official
        votingStart = block.timestamp;
        votingEnd = block.timestamp + (_durationInMinutes * 1 minutes);
    }

    // MODIFIERS (Để tái sử dụng logic kiểm tra)
    
    // 2. RBAC: Chỉ ElectionOfficial mới được gọi 
    modifier onlyOfficial() {
        require(msg.sender == electionOfficial, "Not election official");
        _;
    }

    // 3. TIME-LOCK: Kiểm tra thời gian hợp lệ [cite: 118]
    modifier onlyDuringVoting() {
        require(block.timestamp >= votingStart, "Voting has not started");
        require(block.timestamp <= votingEnd, "Voting has ended");
        _;
    }
    
    // Kiểm tra chưa bỏ phiếu
    modifier hasNotVoted() {
        require(!hasVoted[msg.sender], "You have already voted");
        _;
    }

    // --- CÁC HÀM CHỨC NĂNG ---

    // Hàm thêm ứng cử viên (Chỉ Official) 
    function addCandidate(string memory _name) public onlyOfficial {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, 0, _name);
    }

    // Hàm bỏ phiếu (Voter) [cite: 116]
    function vote(uint256 _candidateId) public onlyDuringVoting hasNotVoted {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");

        // ÁP DỤNG PATTERN: CHECKS-EFFECTS-INTERACTIONS [cite: 13, 79]
        
        // 1. Checks (Đã kiểm tra qua modifiers và require ở trên)

        // 2. Effects (Cập nhật trạng thái)
        hasVoted[msg.sender] = true; // Đánh dấu đã bỏ phiếu 
        candidates[_candidateId].voteCount++; // Tăng số phiếu

        // 3. Interactions (Không có chuyển tiền/call external trong bài này nên bỏ qua)
    }
    
    // Hàm xem số phiếu (Công khai)
    function getVotes(uint256 _candidateId) public view returns (uint256) {
        return candidates[_candidateId].voteCount;
    }
}