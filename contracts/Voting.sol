// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Voting{
    error AlreadyVotedError(string msg);

    address public creator;
    uint topicId;
    uint public numberOfVoters = 0;
    mapping(uint => address[]) voters;
    mapping(uint => Vote[]) votes;
    mapping(uint => VoteMetadata) voteMetadata;

    constructor(){
        creator = msg.sender;
        topicId = 1;
    }

    modifier isCreator(){
        require(msg.sender == creator, "You have insufficient permissions.");
        _;
    }

    modifier hasNotVoted(uint _topicId){
        for(uint i = 0; i < voters[_topicId].length; i++){
            if(voters[_topicId][i] == msg.sender){
                revert AlreadyVotedError("User already voted");
            }
        }
        _;
    }

    struct VoteMetadata{
        Topic topic;
        uint accepted;
        uint rejected;
        bool isOpen;
    }

    struct Topic{
        uint id;
        string topic;
    }

    struct Vote{
        address voter;
        VoteType voteType;
    }

    enum VoteType{
        Accepted,
        Rejected
    }

    function vote(string calldata _voteType, uint _topicId) public hasNotVoted(_topicId) {
        require(voteMetadata[_topicId].isOpen, "Voting is closed");

        voters[_topicId].push(msg.sender);
        numberOfVoters = voters[_topicId].length;
        VoteType voteTypeFromString = parseStringToVoteTypeEnum(_voteType);
        votes[_topicId].push(Vote(msg.sender, voteTypeFromString));

        if(voteTypeFromString == VoteType.Accepted){
            voteMetadata[_topicId].accepted += 1;
        }else if(voteTypeFromString == VoteType.Rejected){
            voteMetadata[_topicId].rejected += 1;
        }
    }

    function getMetadata(uint _topicId) public view returns(VoteMetadata memory){
        return voteMetadata[_topicId];
    }

    function getAcceptedVotesByTopicId(uint _topicId) public view returns (uint){
        return voteMetadata[_topicId].accepted;
    }

    function getRejectedVotesByTopicId(uint _topicId) public view returns (uint){
        return voteMetadata[_topicId].rejected;
    }

    function getTopicApproval(uint _topicId) public view returns(bool){
        return voteMetadata[_topicId].accepted > voteMetadata[_topicId].rejected;
    }

    function createTopic(string calldata _topic) public isCreator returns(bool){
        Topic memory topic = Topic(topicId, _topic);
        voteMetadata[topicId] = VoteMetadata(topic, 0, 0, true);
        topicId++;
        return true;
    }

    function closeVoting(uint _topicId) public isCreator{
        voteMetadata[_topicId].isOpen = false;
    }

    function parseStringToVoteTypeEnum(string calldata _voteType) private pure returns(VoteType){
        bytes32 hashedValue = keccak256(abi.encodePacked(_voteType));
        VoteType voteType;
        
        bytes32 acceptedHash = keccak256(abi.encodePacked("Accepted"));
        bytes32 rejectedHash = keccak256(abi.encodePacked("Rejected"));

        if (hashedValue == acceptedHash) {
            voteType = VoteType.Accepted;
        } else if (hashedValue == rejectedHash) {
            voteType = VoteType.Rejected;
        } else {
            revert("Invalid Vote Type");
        }

        return voteType;
    }

     event VoteCast(uint voters, string voteType, uint topicId);
}