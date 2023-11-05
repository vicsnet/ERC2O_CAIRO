use starknet::ContractAddress;

#[starknet::interface]
trait IERC20Starknet<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn totalSupply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, user_address:ContractAddress) ->u256;
    fn transfer(self: @TContractState, to_address: ContractAddress, value:u256) ->bool;
    fn transferFrom(self: @TContractState, from_address: ContractAddress, to_address: ContractAddress, value:u256)-> bool;
    fn approve(self: @TContractState, spender_address: ContractAddress, value:u256) ->bool;

    fn increase_balance(ref self: TContractState, amount: felt252);
    fn get_balance(self: @TContractState) -> felt252;
}

#[starknet::contract]
mod ERC20Starknet {

use starknet::{ContractAddress, get_caller_address};


    #[storage]
    struct Storage {
        balances: LegacyMap::<ContractAddress, u256>,
        allowed:LegacyMap::<(ContractAddress, ContractAddress), u256>,
        totalSupply:u256,
        name:felt252,
        decimals:u8,
        symbol:felt252,
        // balance: felt252, 
        
    }


#[event]
#[derive(Drop, starknet::Event)]
enum Event{
    Transfer:Transfer,
    Approval:Approval,
}

#[derive(Drop, starknet::Event)]
struct Transfer{
    from_address:ContractAddress,
    to_address:ContractAddress,
    value: u256

}
#[derive(Drop, starknet::Event)]
struct Approval{
owner_address: ContractAddress,
spender_address: ContractAddress,
value:u256

}


#[constructor]
fn constructor(ref self: ContractState, total_supply:u256, _name:felt252, _decimals:u8, _symbol:felt252) {
    self.totalSupply.write(total_supply);
    self.name.write(_name);
    self.decimals.write(_decimals);
    self.symbol.write(_symbol);
    
}
    #[external(v0)]
    impl ERC20StarknetImpl of super::IERC20Starknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.balance.write(self.balance.read() + amount);
        }

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }
    }
}
