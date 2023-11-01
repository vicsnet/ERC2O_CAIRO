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

use starknet::ContractAddress;
use starknet::get_caller_address;

    #[storage]
    struct Storage {
        balance: felt252, 
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
