// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CIX.sol";

/**
 * @title DAO Contract
 * @dev This contract handles various types of proposals including transfers, period extensions, and period changes.
 */
contract DAO {
    // Constants for proposal types
    uint8 public constant TRANSFER_PROPOSAL = 0;
    uint8 public constant END_EXTENSION_PROPOSAL = 1;
    uint8 public constant PERIOD_CHANGE_PROPOSAL = 2;
    uint8 public constant ADD_VOTER_PROPOSAL = 3;
    uint8 public constant REMOVE_VOTER_PROPOSAL = 4;

    // Contract state variables
    uint256 public executionPeriod;
    CIX public cix;
    mapping(address => bool) public isVoter;
    address[] public voters;
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public voted;

    // Proposal struct
    struct Proposal {
        uint8 proposalType;
        string name;
        string description;
        address to;
        uint256 amount;
        uint256 relatedProposal;
        uint256 newEnd;
        address voterAddress;
        uint256 votes;
        uint256 start;
        uint256 end;
        bool executed;
    }

    // Events
    event ProposalCreated(
        uint256 proposalId,
        uint8 proposalType,
        string name,
        string description
    );
    event Voted(uint256 proposal, address indexed voter);
    event ProposalExecuted(uint256 proposalId);
    event VoterAdded(address indexed voter);
    event VoterRemoved(address indexed voter);

    // Constructor to initialize voters and other initial configurations
    constructor(
        address[] memory _voters,
        address _cix,
        uint256 _executionPeriod
    ) {
        for (uint i = 0; i < _voters.length; i++) {
            isVoter[_voters[i]] = true;
        }
        voters = _voters;
        cix = CIX(_cix);
        executionPeriod = _executionPeriod;
    }

    // ------------------- MODIFIERS -------------------

    modifier validProposalDates(uint256 start, uint256 end) {
        require(start < end, "DAO: start must be before end");
        _;
    }

    modifier executable(uint256 proposal) {
        require(proposal < proposals.length, "DAO: proposal does not exist");
        require(!proposals[proposal].executed, "DAO: already executed");
        require(
            proposals[proposal].votes > voters.length / 2,
            "DAO: not enough votes, 50% required"
        );
        require(
            block.timestamp > proposals[proposal].end + executionPeriod,
            "DAO: execution period has not ended"
        );
        _;
    }

    modifier onlyVoter() {
        require(isVoter[msg.sender], "DAO: not a voter");
        _;
    }

    // ------------------- VIEW FUNCTIONS -------------------

    function getBalanceOfDAO() external view returns (uint256) {
        return cix.balanceOf(address(this));
    }

    function getProposal(
        uint256 proposal
    ) external view returns (Proposal memory) {
        require(proposal < proposals.length, "DAO: proposal does not exist");
        return proposals[proposal];
    }

    function getProposals() external view returns (Proposal[] memory) {
        return proposals;
    }

    function getVoters() external view returns (address[] memory) {
        return voters;
    }

    function getVoter(address voter) external view returns (bool) {
        return isVoter[voter];
    }

    // ------------------- PROPOSAL CREATION FUNCTIONS -------------------

    function createTransferProposal(
        string memory name,
        string memory description,
        address to,
        uint256 amount,
        uint256 start,
        uint256 end
    ) public validProposalDates(start, end) onlyVoter {
        proposals.push(
            Proposal({
                proposalType: TRANSFER_PROPOSAL,
                name: name,
                description: description,
                to: to,
                amount: amount,
                relatedProposal: 0,
                newEnd: 0,
                voterAddress: address(0),
                votes: 0,
                start: start,
                end: end,
                executed: false
            })
        );

        emit ProposalCreated(
            proposals.length - 1,
            TRANSFER_PROPOSAL,
            name,
            description
        );
    }

    function createEndExtensionProposal(
        string memory name,
        string memory description,
        uint256 start,
        uint256 end,
        uint256 newEnd,
        uint256 relatedProposal
    ) public validProposalDates(start, end) onlyVoter {
        require(
            relatedProposal < proposals.length,
            "DAO: related proposal does not exist"
        );
        require(
            proposals[relatedProposal].end < newEnd,
            "DAO: new end must be after old end"
        );

        proposals.push(
            Proposal({
                proposalType: END_EXTENSION_PROPOSAL,
                name: name,
                description: description,
                to: address(0),
                amount: 0,
                relatedProposal: relatedProposal,
                newEnd: newEnd,
                voterAddress: address(0),
                votes: 0,
                start: start,
                end: end,
                executed: false
            })
        );

        emit ProposalCreated(
            proposals.length - 1,
            END_EXTENSION_PROPOSAL,
            name,
            description
        );
    }

    function createExecutionPeriodChangeProposal(
        string memory name,
        string memory description,
        uint256 newExecutionPeriod,
        uint256 start,
        uint256 end
    ) public validProposalDates(start, end) onlyVoter {
        proposals.push(
            Proposal({
                proposalType: PERIOD_CHANGE_PROPOSAL,
                name: name,
                description: description,
                to: address(0),
                amount: newExecutionPeriod,
                relatedProposal: 0,
                newEnd: 0,
                voterAddress: address(0),
                votes: 0,
                start: start,
                end: end,
                executed: false
            })
        );

        emit ProposalCreated(
            proposals.length - 1,
            PERIOD_CHANGE_PROPOSAL,
            name,
            description
        );
    }

    function createAddOrRemoveVoterProposal(
        string memory name,
        string memory description,
        address voter,
        bool add,
        uint256 start,
        uint256 end
    ) public validProposalDates(start, end) onlyVoter {
        require(isVoter[voter] != add, "DAO: voter already added or removed");
        proposals.push(
            Proposal({
                proposalType: add ? ADD_VOTER_PROPOSAL : REMOVE_VOTER_PROPOSAL,
                name: name,
                description: description,
                to: address(0),
                amount: 0,
                relatedProposal: 0,
                newEnd: 0,
                voterAddress: voter,
                votes: 0,
                start: start,
                end: end,
                executed: false
            })
        );

        emit ProposalCreated(
            proposals.length - 1,
            add ? ADD_VOTER_PROPOSAL : REMOVE_VOTER_PROPOSAL,
            name,
            description
        );
    }

    // ------------------- PROPOSAL EXECUTION FUNCTIONS -------------------

    function executeTransferProposal(
        uint256 proposal
    ) public executable(proposal) onlyVoter {
        require(
            proposals[proposal].proposalType == TRANSFER_PROPOSAL,
            "DAO: not a transfer proposal"
        );
        cix.transfer(proposals[proposal].to, proposals[proposal].amount);
        proposals[proposal].executed = true;

        emit ProposalExecuted(proposal);
    }

    function executeEndExtensionProposal(
        uint256 proposal
    ) public executable(proposal) onlyVoter {
        require(
            proposals[proposal].proposalType == END_EXTENSION_PROPOSAL,
            "DAO: not an end extension proposal"
        );
        proposals[proposal].executed = true;
        proposals[proposal].end = proposals[proposal].amount;

        emit ProposalExecuted(proposal);
    }

    function executePeriodChangeProposal(
        uint256 proposal
    ) public executable(proposal) onlyVoter {
        require(
            proposals[proposal].proposalType == PERIOD_CHANGE_PROPOSAL,
            "DAO: not a period change proposal"
        );
        proposals[proposal].executed = true;
        executionPeriod = proposals[proposal].amount;

        emit ProposalExecuted(proposal);
    }

    function executeAddOrRemoveVoterProposal(
        uint256 proposal
    ) public executable(proposal) onlyVoter {
        require(
            proposals[proposal].proposalType == ADD_VOTER_PROPOSAL ||
                proposals[proposal].proposalType == REMOVE_VOTER_PROPOSAL,
            "DAO: not an add or remove voter proposal"
        );
        proposals[proposal].executed = true;
        isVoter[proposals[proposal].voterAddress] =
            proposals[proposal].proposalType == ADD_VOTER_PROPOSAL;
        if (proposals[proposal].proposalType == ADD_VOTER_PROPOSAL) {
            voters.push(proposals[proposal].voterAddress);
        } else {
            for (uint256 i = 0; i < voters.length; i++) {
                if (voters[i] == proposals[proposal].voterAddress) {
                    voters[i] = voters[voters.length - 1];
                    voters.pop();
                    break;
                }
            }
        }

        emit ProposalExecuted(proposal);
    }

    // ------------------- VOTING FUNCTIONS -------------------

    function vote(uint256 proposal) public onlyVoter {
        require(proposal < proposals.length, "DAO: proposal does not exist");
        require(!voted[proposal][msg.sender], "DAO: already voted");
        require(
            block.timestamp > proposals[proposal].start,
            "DAO: voting has not started"
        );
        require(
            block.timestamp < proposals[proposal].end,
            "DAO: voting has ended"
        );
        voted[proposal][msg.sender] = true;
        proposals[proposal].votes++;

        emit Voted(proposal, msg.sender);
    }
}
