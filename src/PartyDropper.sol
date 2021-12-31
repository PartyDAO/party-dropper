// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "./Base64.sol";
import "./IPartyBid.sol";

contract PartyDropper is ERC1155Supply, Ownable {
    struct Edition {
        IPartyBid party;
        string name;
        string imageURI;
        string description;
    }
    mapping(uint256 => Edition) public editions;
    mapping(uint256 => mapping(address => bool)) public editionMinter;
    mapping(uint256 => address) public editionCreator;
    mapping(address => bool) public allowedCreators;
    uint256 lastEditionId;

    event EditionCreated(
        uint256 indexed editionId,
        address indexed creator,
        address party,
        string name
    );
    event Claimed(address indexed user, uint256 indexed editionId);

    modifier onlyAllowedCreator() {
        require(
            allowedCreators[msg.sender] || msg.sender == owner(),
            "must be allowed creator or owner"
        );
        _;
    }

    constructor() ERC1155("") {}

    // public functions
    function mintFromEdition(uint256 editionId) public {
        Edition storage edition = editions[editionId];
        require(
            edition.party.totalContributed(msg.sender) > 0,
            "didn't contribute to PartyBid"
        );
        require(!editionMinter[editionId][msg.sender], "already minted");
        editionMinter[editionId][msg.sender] = true;
        _mint(msg.sender, editionId, 1, "");
        emit Claimed(msg.sender, editionId);
    }

    function editionInfo(uint256 editionId)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            string memory
        )
    {
        Edition storage fnd = editions[editionId];
        return (address(fnd.party), fnd.name, fnd.imageURI, fnd.description);
    }

    function uri(uint256 editionId)
        public
        view
        override
        returns (string memory)
    {
        require(editionId <= lastEditionId, "must be created");
        Edition storage edition = editions[editionId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        edition.name,
                        '", "description": "',
                        edition.description,
                        '", "image": "',
                        edition.imageURI,
                        '"}'
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }

    // allowedCreator functions
    function createEdition(
        address _party,
        string memory _name,
        string memory _imageURI,
        string memory _description
    ) public onlyAllowedCreator {
        lastEditionId += 1;
        IPartyBid party = IPartyBid(_party);
        editions[lastEditionId] = Edition({
            party: party,
            name: _name,
            imageURI: _imageURI,
            description: _description
        });
        editionCreator[lastEditionId] = msg.sender;
        emit EditionCreated(lastEditionId, msg.sender, address(_party), _name);
    }

    // owner functions
    function setAllowedCreator(address _address, bool _value) public onlyOwner {
        allowedCreators[_address] = _value;
    }
}
