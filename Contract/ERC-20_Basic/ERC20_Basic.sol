// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/**
* Interface 는 사용할 함수의 형태를 선언합니다.
* 실제 함수의 내용은 Contract 에서 사용합니다.
* function 은 이더리움에서 제공하는 함수
* event 는 이더리움에서 제공하는 로그
*/
interface ERC20Interface{
    // 해당 스마트 컨트랙트 기반 ERC-20 토큰의 총 발행량 확인
    function totalSupply () external view returns (uint256);
    
    // owner 가 가지고 있는 토큰의 보유량 확인
    function balanceOf (address account) external view returns (uint256);
    
    // 토큰 전송
    function transfer (address recipient, uint256 amount) external returns (bool);
    
    // spender 에게 value 만큼의 토큰을 인출할 권리를 부여, 이 함수를 이용할 때는 반드시 Approval 이벤트 함수를 호출해야 한다. approve:승인하다
    function approve (address spender, uint256 amount) external returns (bool);

    // owner 가 spender 에게 양도 설정한 토큰의 양을 확인. allowance : 용돈, spender : 돈쓰는사람
    function allowance(address owner, address spender) external view returns (uint256);

    // spender 가 거래가능 하도록 양도 받은 토큰을 전송. recipient : 받는사람
    function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);

    /* Transfer 이벤트는 토큰이 이동할 때마다 로그를 남깁니다 */
    /* Approval 이벤트는 approve 함수가 실행될 때 로그를 남깁니다. */
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Transfer(address indexed spender, address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 oldAmount, uint256 amount);
}


contract SimpleToken is ERC20Interface{
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    uint256 public _totalSupply;
    string public _name;
    string public _symbol;
    uint8 public _decimals;

    constructor (string memory getName, string memory getSymbol){
        _name = getName;
        _symbol = getSymbol;
        _decimals = 18;
        _totalSupply = 100000000e18;
        _balances[msg.sender] = _totalSupply; //msg 는 글로벌 변수. 호출하고있는 발신자의 주소입니다.

    }

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function decimals() public view returns (uint8){
        return _decimals;
    }

    function totalSupply() external view virtual override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns(uint256){
        return _balances[account];
    }

    /* 이거는 ERC20Interface 에서 상속한것이다.
    * 받는사람 주소와 토큰양을 지정하면, 주소유무와 잔액검증 후에, 받는사람에게 amount 만큼 토큰을 더해줍니다.
    */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool){
        _transfer(msg.sender, recipient, amount); // 검증후 보내는것
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual{
        // require 를 통해 세가지 조건 검사
        require(sender != address(0), "ERC20: transfer from the zero address"); // 보내는 사람의 주소가 없다? address 의 null 검사?
        require(recipient != address(0), "ERC20 : transfer to the zero address"); // 받는사람의 주소가 없다

        uint256 senderBalance = _balances[sender]; // 요청한 사람의 잔액
        
        require(senderBalance >= amount, "ERC20 : transfer amount exeed balance"); // 보낸사람의 토큰 잔액이 보내려는값보다 커야한다, 아니면 에러.

        // 송금 처리
        _balances[sender] = senderBalance-amount;
        _balances[recipient] += amount;
    }

    function transferFrom (address sender, address recipient, uint256 amount) external virtual override returns(bool){
        _transfer(sender, recipient, amount); // 송금, 여기서 송금 처리 하면,
        emit Transfer(msg.sender, sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender]; // spender 중개자가 출금하나 보다.
        require(currentAllowance >= amount, "ERC20 : transfer amount exceeds allowance");
        _approve(sender,msg.sender, currentAllowance, currentAllowance-amount); // 여기서 양도 받은 금액 에서 출금한 금액 차감하여 적용하는것 처리.
        return true;
        
    }

    // 승인. spender 가 당신의 계정으로부터 amount 한도 하에서 여러번 출금하는것을 허용합니다.
    function approve (address spender, uint amount) external virtual override returns (bool){
        uint256 currentAllowance = _allowances[msg.sender][spender]; // _allowances[주인][양도받은자] = 원래주인으로부터 양도받은 토큰양
        require(currentAllowance >= amount, "ERC20 : transfer amount exceeds allowance"); //송금금액이 한도를 초과합니다.
        _approve(msg.sender, spender, currentAllowance, amount);
        return true;
    }

    // Spender 에게 맡긴 금액 실제로 기록하는 함수.
    function _approve(address owner, address spender, uint256 currentAmount, uint256 amount) internal virtual{
        require(owner != address(0),"ERC20 : approve from the zero address."); //적합하지 않은 주소가 승인하려고 합니다
        require(spender != address(0), "ERC20 : approve to the zero address."); //적합하지 않은 주소에게 승인하려고 합니다
        require(currentAmount == _allowances[owner][spender], "ERC20 : invalid current Amount.");//유효하지 않은 양입니다

        // 금액 양도
        _allowances[owner][spender] = amount;
        emit Approval(owner,spender,currentAmount, amount);
    }
    
    //owner가 spender에게 토큰을 등록한 양을 반환
    function allowance(address owner, address spender) external view override returns (uint256){
        return _allowances[owner][spender];
    }



}