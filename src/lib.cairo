use starknet::ContractAddress;

#[starknet::interface]
trait IERC20Starknet<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn total_Supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, user_address: ContractAddress) -> u256;
     fn allowance(self:@TContractState, user_address:ContractAddress, allowed_adddress:ContractAddress)->u256;
    fn transfer(ref self: TContractState, to_address: ContractAddress, value: u256) -> bool;
    fn transfer_from(
        ref self: TContractState,
        from_address: ContractAddress,
        to_address: ContractAddress,
        value: u256
    ) -> bool;
    fn approve(ref self: TContractState, spender_address: ContractAddress, value: u256) -> bool;
    fn increase_allowance(
        ref self: TContractState, spender_address: ContractAddress, value: u256
    ) -> bool ;
    fn decrease_allowance(
        ref self: TContractState, spender_address: ContractAddress, value: u256
    ) -> bool;
       fn burn(ref self: TContractState, value: u256) -> bool ;

    fn mintT(ref self: TContractState, value: u256) -> bool;
}

#[starknet::contract]
mod ERC20Starknet {
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::contract_address::ContractAddressZeroable;


    #[storage]
    struct Storage {
        balances: LegacyMap::<ContractAddress, u256>,
        allowed: LegacyMap::<(ContractAddress, ContractAddress), u256>,
        total_supply: u256,
        name: felt252,
        symbol: felt252,
        decimals: u8,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from_address: ContractAddress,
        to_address: ContractAddress,
        value: u256
    }
    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner_address: ContractAddress,
        spender_address: ContractAddress,
        value: u256
    }


    #[constructor]
    fn constructor(
        ref self: ContractState,
        _total_supply: u256,
        _name: felt252, 
        _decimals: u8,
        _symbol: felt252,
        _amount: u256
    ) {
        let caller = get_caller_address();
        self.total_supply.write(_total_supply);
        self.name.write(_name);
        self.decimals.write(_decimals);
        self.symbol.write(_symbol);
        self._mint(caller, _amount);
    }
    #[external(v0)]
    impl ERC20StarknetImpl of super::IERC20Starknet<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }
        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }
        fn decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }
        fn total_Supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }
        fn balance_of(self: @ContractState, user_address: ContractAddress) -> u256 {
            self.balances.read(user_address)
        }
        fn allowance(self:@ContractState, user_address:ContractAddress, allowed_adddress:ContractAddress)->u256{

        self.allowed.read((user_address, allowed_adddress))
        }

        fn transfer(ref self: ContractState, to_address: ContractAddress, value: u256) -> bool {
            let caller = get_caller_address();
            // let address0 = ContractAddressZeroable();
            assert(self.balances.read(caller) >= value, 'insufficient amount');
            assert(!to_address.is_zero(), 'zero address');
            self.balances.write(caller, self.balances.read(caller) - value);
            self.balances.write(to_address, self.balances.read(to_address) + value);
            self.emit(Transfer { from_address: caller, to_address: to_address, value: value });
            true
        }
        fn transfer_from(
            ref self: ContractState,
            from_address: ContractAddress,
            to_address: ContractAddress,
            value: u256
        ) -> bool {
            let caller = get_caller_address();
            assert(self.balances.read(from_address) >= value, 'Insufficient balance');
            assert(self.allowed.read((from_address, caller)) >= value, 'insufficient allowance');
            self
                .allowed
                .write((from_address, caller), self.allowed.read((from_address, caller)) - value);
            self.balances.write(from_address, self.balances.read(from_address) - value);
            self.balances.write(to_address, self.balances.read(to_address) + value);
            self
                .emit(
                    Transfer { from_address: from_address, to_address: to_address, value: value }
                );
            true
        }
        fn approve(ref self: ContractState, spender_address: ContractAddress, value: u256) -> bool {
            let caller = get_caller_address();
            assert(!spender_address.is_zero(), 'zero address');

            self
                .allowed
                .write(
                    (caller, spender_address), self.allowed.read((caller, spender_address)) + value
                );
            self
                .emit(
                    Approval {
                        owner_address: caller, spender_address: spender_address, value: value
                    }
                );
            true
        }

         fn increase_allowance(
        ref self: ContractState, spender_address: ContractAddress, value: u256
    ) -> bool {
        let caller = get_caller_address();

        assert(!spender_address.is_zero(), 'zero address');
        self
            .allowed
            .write((caller, spender_address), self.allowed.read((caller, spender_address)) + value);
        self
            .emit(
                Approval { owner_address: caller, spender_address: spender_address, value: value }
            );
        true
    }

  
    fn decrease_allowance(
        ref self: ContractState, spender_address: ContractAddress, value: u256
    ) -> bool {
        let caller = get_caller_address();
        assert(!spender_address.is_zero(), 'zero address');
        self
            .allowed
            .write((caller, spender_address), self.allowed.read((caller, spender_address)) - value);
        self
            .emit(
                Approval { owner_address: caller, spender_address: spender_address, value: value }
            );
        true
    }
   
    fn burn(ref self: ContractState, value: u256) -> bool {
        let caller = get_caller_address();
        self._burn(caller, value);
        true
    }

    fn mintT(ref self: ContractState, value: u256) -> bool {
        let caller = get_caller_address();
            self._mint(caller, value);
        true
    }
    }
    #[generate_trait]
    impl Private of PrivateTrait {
        fn _burn(ref self: ContractState, from_address: ContractAddress, value: u256) {
            let Address0: ContractAddress = 0.try_into().unwrap();
            assert(!from_address.is_zero(), 'zero address');
            assert(self.balances.read(from_address) >= value, 'insufficient fund');
            self.balances.write(from_address, self.balances.read(from_address) - value);
            self.total_supply.write(self.total_supply.read() - value);
            self.emit(Transfer { from_address: from_address, to_address: Address0, value: value });
        }

        fn _mint(ref self: ContractState, owner: ContractAddress, value: u256) {
            let addr = get_contract_address();
            assert(!owner.is_zero(), 'zero address');
            let mybalance = self.balances.read(owner);
            self.balances.write(owner, (mybalance + value));
            self.emit(Transfer { from_address: addr, to_address: owner, value: value, });
        }
    }



   
}

#[cfg(test)]
mod tests {
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use array::ArrayTrait;
    use result::ResultTrait;
    use debug::PrintTrait;
    use option::OptionTrait;
    use traits::TryInto;
    use starknet::Felt252TryIntoContractAddress;

    use super::IERC20StarknetSafeDispatcher;
    use super::IERC20StarknetDispatcher;
    use super::IERC20StarknetSafeDispatcherTrait;
    use super::Accounts::{user1, user2, user3, user4, user5};



const token_supply:u256=2000;
const token_name:felt252 = 'erc20Token';
const token_decimal:u8 = 16;
const token_symbol:felt252= 'E2T';
const token_amount:u256=2000;
 const amount:u256 = 0;

mod Error{
    const INVALID_NAME: felt252 = ' invalid name';
    const INVALID_SYMBOL:felt252 = 'invalid symbol';
    const INVALID_DECIMAL:felt252 = 'invalid symbol';
    const INVALID_SUPPLY:felt252 = 'invalid symbol';
    const INVALID_AMMOUNT:felt252 = 'wrong amount';
}
    
    fn deploy() -> ContractAddress {
        let contract = declare('ERC20Starknet');
        // let erc20_calldata = array![token_supply, name, token_decimal, token_symbol, token_amount];
        let mut calldata = ArrayTrait::new();
        token_supply.serialize(ref calldata);
        token_name.serialize(ref calldata);
        token_decimal.serialize(ref calldata);
        token_symbol.serialize(ref calldata);
        token_amount.serialize(ref calldata);
        let contract_address = contract.precalculate_address(@calldata);
        start_prank(contract_address, user1());
        let contract_address = contract.deploy(@calldata).unwrap();
        stop_prank(contract_address);
        contract_address
       
    }
    #[test]
    fn test_deploy() {
        let my_addr = deploy();
        my_addr.print();
    }
    #[test]
    fn test_read_func(){
        let contract_address = deploy();
        let dispatcher =IERC20StarknetSafeDispatcher{contract_address};
        let result_token_name = dispatcher.name().unwrap();
        let result_token_symbol= dispatcher.symbol().unwrap();
        let result_token_decimals = dispatcher.decimals().unwrap();
        let result_token_supply = dispatcher.total_Supply().unwrap();
        result_token_supply.print();
        assert(result_token_name == token_name, Error::INVALID_NAME);
        assert(result_token_symbol == token_symbol, Error::INVALID_SYMBOL);
        assert(result_token_decimals == token_decimal, Error::INVALID_DECIMAL);
        assert(result_token_supply == token_supply, Error::INVALID_SUPPLY);
    }

    #[test]
    fn test_balance_func(){
       
        let contract_address = deploy();

        let dispatcher = IERC20StarknetSafeDispatcher{contract_address};

        let caller= get_caller_address();

        let result_balance_of = dispatcher.balance_of(user1()).unwrap();
        result_balance_of.print();
        assert(result_balance_of == token_amount, 'wrong Token Balance');
   

        start_prank(contract_address, user2());
        let result_mint = dispatcher.mintT(100).unwrap();
        assert(result_mint ==true, 'call failed');
        let result_balance_of = dispatcher.balance_of(user2()).unwrap();
        assert(result_balance_of == 100_u256, 'wrong Balance');
        
        stop_prank(contract_address);
    }
    #[test]
    fn test_transfer_func(){

        let contract_address = deploy();
        let dispatcher = IERC20StarknetSafeDispatcher{contract_address};
        start_prank(contract_address, user1());
        let result_transfer = dispatcher.transfer(user3(), 200).unwrap();
        stop_prank(contract_address);
        let result_balance_of = dispatcher.balance_of(user3()).unwrap();
        assert(result_balance_of == 200, Error::INVALID_AMMOUNT);

    }

    #[test]
    fn test_transfer_from_func(){
        let contract_address = deploy();
        let dispatcher = IERC20StarknetSafeDispatcher{contract_address};
        start_prank(contract_address, user1());
        let result_approve = dispatcher.approve(user5(), 100).unwrap();
        stop_prank(contract_address);
        let result_allowance= dispatcher.allowance(user1(), user5()).unwrap();
        assert(result_allowance == 100, 'wrong allowance');

        start_prank(contract_address, user5());
        let result_transfer_from= dispatcher.transfer_from(user1(), user4(), 100).unwrap();
        stop_prank(contract_address);
        

        let result_balance_of= dispatcher.balance_of(user4()).unwrap();
        assert(result_balance_of ==100, Error::INVALID_AMMOUNT);
    }

    #[test]
    fn test_burn(){
        let contract_address = deploy();
        let dispatcher = IERC20StarknetSafeDispatcher{contract_address};
        start_prank(contract_address, user1());
        let result_burn = dispatcher.burn(1000);
        stop_prank(contract_address);
      let result_balance_of= dispatcher.balance_of(user1()).unwrap();
        assert(result_balance_of ==1000, Error::INVALID_AMMOUNT);


    }
}

mod Accounts{
use starknet::ContractAddress;
use traits::TryInto;

fn user1()->ContractAddress{
    'user'.try_into().unwrap()
}
fn user2()->ContractAddress{
    'user1'.try_into().unwrap()
}
fn user3()->ContractAddress{
    'user3'.try_into().unwrap()
}
fn user4()->ContractAddress{
    'user4'.try_into().unwrap()
}
fn user5()->ContractAddress{
    'user4'.try_into().unwrap()
}
}