
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Avatar Chain
 * @dev A decentralized avatar management system on blockchain
 * @author Avatar Chain Team
 */
contract Project {
    // Avatar structure to store avatar data
    struct Avatar {
        uint256 id;
        string name;
        string imageHash; // IPFS hash for avatar image
        address owner;
        uint256 createdAt;
        bool isActive;
        uint256 level;
        string[] attributes; // Dynamic attributes like skills, achievements
    }

    // State variables
    mapping(uint256 => Avatar) public avatars;
    mapping(address => uint256[]) public userAvatars;
    mapping(address => bool) public registeredUsers;
    
    uint256 public nextAvatarId;
    uint256 public totalAvatars;
    address public owner;
    
    // Events
    event AvatarCreated(uint256 indexed avatarId, address indexed owner, string name);
    event AvatarUpdated(uint256 indexed avatarId, string name, uint256 level);
    event AvatarTransferred(uint256 indexed avatarId, address indexed from, address indexed to);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    modifier onlyAvatarOwner(uint256 _avatarId) {
        require(avatars[_avatarId].owner == msg.sender, "You don't own this avatar");
        require(avatars[_avatarId].isActive, "Avatar is not active");
        _;
    }

    modifier validAvatarId(uint256 _avatarId) {
        require(_avatarId > 0 && _avatarId < nextAvatarId, "Invalid avatar ID");
        _;
    }

    constructor() {
        require(msg.sender != address(0), "Zero address");
        owner = msg.sender;
        nextAvatarId = 1;
        totalAvatars = 0;
    }

    /**
     * @dev Core Function 1: Create a new avatar
     * @param _name Avatar name
     * @param _imageHash IPFS hash of avatar image
     * @param _initialAttributes Initial attributes for the avatar
     */
    function createAvatar(
        string memory _name,
        string memory _imageHash,
        string[] memory _initialAttributes
    ) external returns (uint256) {
        require(bytes(_name).length > 0, "Avatar name cannot be empty");
        require(bytes(_imageHash).length > 0, "Image hash cannot be empty");

        uint256 avatarId = nextAvatarId;
        
        avatars[avatarId] = Avatar({
            id: avatarId,
            name: _name,
            imageHash: _imageHash,
            owner: msg.sender,
            createdAt: block.timestamp,
            isActive: true,
            level: 1,
            attributes: _initialAttributes
        });

        userAvatars[msg.sender].push(avatarId);
        registeredUsers[msg.sender] = true;
        
        nextAvatarId++;
        totalAvatars++;

        emit AvatarCreated(avatarId, msg.sender, _name);
        return avatarId;
    }

    /**
     * @dev Core Function 2: Update avatar properties and level up
     * @param _avatarId ID of the avatar to update
     * @param _newName New name for the avatar (optional, pass empty string to keep current)
     * @param _newImageHash New image hash (optional, pass empty string to keep current)
     * @param _levelIncrease Amount to increase level by
     * @param _newAttributes New attributes to add
     */
    function updateAvatar(
        uint256 _avatarId,
        string memory _newName,
        string memory _newImageHash,
        uint256 _levelIncrease,
        string[] memory _newAttributes
    ) external onlyAvatarOwner(_avatarId) validAvatarId(_avatarId) {
        Avatar storage avatar = avatars[_avatarId];
        
        // Update name if provided
        if (bytes(_newName).length > 0) {
            avatar.name = _newName;
        }
        
        // Update image hash if provided
        if (bytes(_newImageHash).length > 0) {
            avatar.imageHash = _newImageHash;
        }
        
        // Level up avatar
        if (_levelIncrease > 0) {
            avatar.level += _levelIncrease;
        }
        
        // Add new attributes
        for (uint256 i = 0; i < _newAttributes.length; i++) {
            avatar.attributes.push(_newAttributes[i]);
        }

        emit AvatarUpdated(_avatarId, avatar.name, avatar.level);
    }

    /**
     * @dev Core Function 3: Transfer avatar ownership
     * @param _avatarId ID of the avatar to transfer
     * @param _newOwner Address of the new owner
     */
    function transferAvatar(
        uint256 _avatarId,
        address _newOwner
    ) external onlyAvatarOwner(_avatarId) validAvatarId(_avatarId) {
        require(_newOwner != address(0), "Cannot transfer to zero address");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");

        Avatar storage avatar = avatars[_avatarId];
        address previousOwner = avatar.owner;
        
        // Update avatar owner
        avatar.owner = _newOwner;
        
        // Remove from previous owner's list
        _removeAvatarFromUser(previousOwner, _avatarId);
        
        // Add to new owner's list
        userAvatars[_newOwner].push(_avatarId);
        registeredUsers[_newOwner] = true;

        emit AvatarTransferred(_avatarId, previousOwner, _newOwner);
    }

    /**
     * @dev Get avatar details by ID
     * @param _avatarId ID of the avatar
     */
    function getAvatar(uint256 _avatarId) 
        external 
        view 
        validAvatarId(_avatarId) 
        returns (
            uint256 id,
            string memory name,
            string memory imageHash,
            address avatarOwner,
            uint256 createdAt,
            bool isActive,
            uint256 level,
            string[] memory attributes
        ) 
    {
        Avatar memory avatar = avatars[_avatarId];
        return (
            avatar.id,
            avatar.name,
            avatar.imageHash,
            avatar.owner,
            avatar.createdAt,
            avatar.isActive,
            avatar.level,
            avatar.attributes
        );
    }

    /**
     * @dev Get all avatar IDs owned by a user
     * @param _user Address of the user
     */
    function getUserAvatars(address _user) external view returns (uint256[] memory) {
        return userAvatars[_user];
    }

    /**
     * @dev Get total number of avatars created
     */
    function getTotalAvatars() external view returns (uint256) {
        return totalAvatars;
    }

    /**
     * @dev Deactivate an avatar (only owner can do this)
     * @param _avatarId ID of the avatar to deactivate
     */
    function deactivateAvatar(uint256 _avatarId) 
        external 
        onlyAvatarOwner(_avatarId) 
        validAvatarId(_avatarId) 
    {
        avatars[_avatarId].isActive = false;
    }

    /**
     * @dev Reactivate an avatar (only owner can do this)
     * @param _avatarId ID of the avatar to reactivate
     */
    function reactivateAvatar(uint256 _avatarId) 
        external 
        onlyAvatarOwner(_avatarId) 
        validAvatarId(_avatarId) 
    {
        avatars[_avatarId].isActive = true;
    }

    /**
     * @dev Internal function to remove avatar from user's list
     * @param _user User address
     * @param _avatarId Avatar ID to remove
     */
    function _removeAvatarFromUser(address _user, uint256 _avatarId) internal {
        uint256[] storage userAvatarList = userAvatars[_user];
        for (uint256 i = 0; i < userAvatarList.length; ) {
            if (userAvatarList[i] == _avatarId) {
                userAvatarList[i] = userAvatarList[userAvatarList.length - 1];
                userAvatarList.pop();
                continue; // Check for duplicates
            }
            unchecked { i++; }
        }
    }

    /**
     * @dev Emergency function to pause contract (only contract owner)
     */
    function emergencyPause() external onlyOwner {
        // Implementation for emergency pause if needed
        // This is a placeholder for future emergency functionality
    }
}
