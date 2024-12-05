#[starknet::interface]
trait ICounter<T> {
    fn get_counter(self: @T) -> u32;
    fn increase_counter(ref self: T);
    fn decrease_counter(ref self: T);
    fn reset_counter(ref self: T);
}

#[starknet::contract]
mod Counter {
    use OwnableComponent::InternalTrait;
use super::ICounter;
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use openzeppelin_access::ownable::OwnableComponent;

    component!(path:OwnableComponent, storage: ownable, event: OwnableEvent);

    // OwnableMixin
    #[abi(embed_v0)]
    impl OwnableMixin = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableCamelOnlyImpl = OwnableComponent::OwnableCamelOnlyImpl<ContractState>;
    
    #[storage]
    struct Storage {
        counter: u32,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncremented: CounterIncremented,
        CounterDecreased: CounterDecreased,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncremented {
        counter: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterDecreased {
        counter: u32,
    }
    pub mod Errors {
        pub const COUNTER_CANNOT_BE_NEGATIVE: felt252 = 'Counter cannot be negative';
    }

    #[constructor]
    fn constructor(ref self: ContractState, init_value: u32, owner: ContractAddress) {
        self.counter.write(init_value);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl CounterImpl of ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) {
            let current_value = self.counter.read();
            self.counter.write(current_value + 1);

            self.emit(CounterIncremented { counter: current_value + 1 });
        }

        fn decrease_counter(ref self: ContractState) {
            let current_value = self.counter.read();
            let new_counter = current_value - 1;
            assert(new_counter > 0, Errors::COUNTER_CANNOT_BE_NEGATIVE);

            self.counter.write(current_value - 1);
            self.emit(CounterDecreased { counter: current_value - 1 });
        }

        fn reset_counter(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.counter.write(0);
        }
    }
}

// #[test]
// fn test_counter() {
//     let initial_counter = 1;
//     let contract_address = deploy_contract(initial_counter);
//     let counter = Counter::constructor(10);

//     assert_eq!(counter.get_counter(), 10);
// }

// use starknet::{ContractAddress};
// use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

// pub fn deploy_contract(initial_value: u32) -> ContractAddress {
//     let contract = declare("counter_contract").unwrap().contract_class();
//     let constructor_args = array![initial_value.into()];
//     let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
//     contract_address
// }