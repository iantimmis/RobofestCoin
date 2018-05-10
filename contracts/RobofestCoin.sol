pragma solidity ^0.4.0;

interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface ERC223 {
    function transfer(address _to, uint _value, bytes _data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract Token {
    string internal _symbol;
    string internal _name;
    uint8 internal _decimals;
    uint internal _totalSupply = 1000;
    mapping (address => uint) internal _balanceOf;
    mapping (address => mapping (address => uint)) internal _allowances;

    function Token(string symbol, string name, uint8 decimals, uint totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
    }

    function name() public view returns (string) {
        return _name;
    }

    function symbol() public view returns (string) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract RoboCore is Token("ROBO_t1", "Robofest Coin Test Version 1", 18, 1000000), ERC20, ERC223 {

    using SafeMath for uint;

    function RoboCore() public {
        _balanceOf[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public view returns (uint) {
        return _balanceOf[_addr];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        if (_value > 0 &&
            _value <= _balanceOf[msg.sender] &&
            !isContract(_to)) {
            _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transfer(address _to, uint _value, bytes _data) external returns (bool) {
        if (_value > 0 && _value <= _balanceOf[msg.sender] && isContract(_to)) 
        {
            _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
            _contract.tokenFallback(msg.sender, _value, _data);
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        return false;
    }

    function isContract(address _addr) private view returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        if (_allowances[_from][msg.sender] > 0 && _value > 0 &&
            _allowances[_from][msg.sender] >= _value && _balanceOf[_from] >= _value) 
        {
            _balanceOf[_from] = _balanceOf[_from].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint _value) external returns (bool) {
        _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender].add(_value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint) {
        return _allowances[_owner][_spender];
    }
}

contract RobofestCoin is RoboCore {
    
    address contractOwner;

    mapping (address => bool) distro_addresses;
    mapping (string => bool) distro_emails;

    mapping (address => bool) register_addresses;
    mapping (string => bool) register_emails;

    modifier auth {
        require(msg.sender == contractOwner);
        _;
    }

    function RobofestCoin() public {
        contractOwner = msg.sender;
    }

    function mint(uint256 _amount) external auth {
        _balanceOf[contractOwner] = _balanceOf[contractOwner].add(_amount);
        _totalSupply = _totalSupply.add(_amount);
    }

    function burn(uint256 _amount) external auth {
        _balanceOf[contractOwner] = _balanceOf[contractOwner].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
    }

    function transferFromPVT(address from, address to, uint value) private returns (bool) {
        bool success = false;

        if (value > 0 && _balanceOf[from] >= value) {
            _balanceOf[from] = _balanceOf[from].sub(value);
            _balanceOf[to] = _balanceOf[to].add(value);
            success = true;
        }

        return success;
    }

    function distributeCoin(address addr, string email) external auth returns (bool) {
        bool success = false;
        
        // Check if user is valid
        if (distro_addresses[addr] == false && distro_emails[email] == false) {
            
            // Add 1 coin to address
            if (transferFromPVT(contractOwner, addr, 1) == true) {
                
                // Distribute coin to user
                success = true;
                distro_addresses[addr] = true;
                distro_emails[email] = true;
            }
        }
        
        return success;
    }

    function registerParticipant(address addr, string email) external auth returns (bool) {
        bool success = false;
        
        // Check if participant is valid
        if (register_addresses[addr] == false && register_emails[email] == false && _balanceOf[addr] >= 1)
        {
            success = true;

            // Subtract 1 coin from address
            if (transferFromPVT(addr, contractOwner, 1) == true) {
                
                // Register participant
                register_addresses[addr] = true;
                register_emails[email] = true;
            }
        }
        
        return success;
    }

    function isRegistered(address addr) external view returns (bool) {
        return register_addresses[addr];
    }

    function isRegistered(string email) external view returns (bool) {
        return register_emails[email];
    }
}