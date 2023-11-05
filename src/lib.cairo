use starknet::ContractAddress;

#[starknet::interface]
trait IERC20Starknet<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn total_Supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, user_address: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, to_address: ContractAddress, value: u256) -> bool;
    fn transfer_from(
        ref self: TContractState,
        from_address: ContractAddress,
        to_address: ContractAddress,
        value: u256
    ) -> bool;
    fn approve(ref self: TContractState, spender_address: ContractAddress, value: u256) -> bool;

}

#[starknet::contract]
mod ERC20Starknet {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::contract_address::ContractAddressZeroable;


    #[storage]
    struct Storage {
        balances: LegacyMap::<ContractAddress, u256>,
        allowed: LegacyMap::<(ContractAddress, ContractAddress), u256>,
        total_supply: u256,
        name: felt252,
        decimals: u8,
        symbol: felt252,
    // balance: felt252, 

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
        _symbol: felt252
    ) {
        self.total_supply.write(_total_supply);
        self.name.write(_name);
        self.decimals.write(_decimals);
        self.symbol.write(_symbol);
    }
    #[external(v0)]
    impl ERC20StarknetImpl of super::IERC20Starknet<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name.read();
        }
        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read();
        }
        fn decimals(self: @ContractState) -> u8 {
            self.decimals.read();
        }
        fn total_Supply(self: @ContractState) -> u256 {
            self.total_supply.read();
        }
        fn balance_of(self: @ContractState, user_address: ContractAddress) -> u256 {
            self.balances.read(user_address);
        }

        fn transfer(ref self: ContractState, user_address: ContractAddress, value: u256) -> bool {
            let caller = get_caller_address();
            let address0 = ContractAddressZeroable();
            assert(self.balances.read(caller) >= value, 'insufficient amount');
            assert(user_address != address0, 'transfer to 0 address not allowed');
            self.balances.write(caller, self.balances.read(caller) - value);
            self.balances.write(user_address, self.balances.read(user_address) + value);
            self.emit(Transfer { from_address: caller, to_address: user_address, value: value });
            true;
        }
        fn transfer_from(
            ref self: ContractState,
            from_address: ContractAddress,
            to_address: ContractAddress,
            value: u256
        ) -> bool {
            let caller = get_caller_address();
            assert(self.balances.read(from_address) >= value, 'Insufficient balance');
            assert(self.allowed.read(from_address, caller) >= value, 'insufficient allowance');
            self
                .allowed
                .write(from_address, caller, self.allowed.read(from_address, caller) - value);
            self.balances.write(from_address, self.balances.read(from_address) - value);
            self.balances.write(to_address, self.balances.read(to_address) + value);
            self
                .emit(
                    Transfer { from_address: from_address, to_address: to_address, value: value }
                );
            true;
        }
        fn approve(ref self: ContractState, spender_address: ContractAddress, value: u256) -> bool {
            let caller = get_caller_address();
            let address0 = ContractAddressZeroable();
            assert(spender_address != address0);

            self
                .allowed
                .write(caller, spender_address, self.allowed.read(caller, spender_address) + value);
            self
                .emit(
                    Approval {
                        owner_address: caller, spender_address: spender_address, value: value
                    }
                );
            true;
        }

    }




    
}
