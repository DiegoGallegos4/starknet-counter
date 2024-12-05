#[starknet::interface]
trait ICounter<T> {
    fn get_counter(self: @T) -> u32;
    fn increase_counter(ref self: T);
    fn decrease_counter(ref self: T);
    fn reset_counter(ref self: T);
}

#[starknet::contract]
mod Counter {
    use super::ICounter;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    
    #[storage]
    struct Storage {
        counter: u32,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncremented: CounterIncremented,
        CounterDecreased: CounterDecreased,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncremented {
        counter: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterDecreased {
        counter: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState, init_value: u32) {
        self.counter.write(init_value);
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
            self.counter.write(current_value - 1);

            self.emit(CounterDecreased { counter: current_value - 1 });
        }

        fn reset_counter(ref self: ContractState) {
            self.counter.write(0);
        }
    }
}
