#[starknet::interface]
trait ISimple<TContractState> {
    fn emit_event(ref self: TContractState);
}

#[starknet::contract]
mod simple_contact {
    use core::starknet::{ContractAddress, get_caller_address};
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event, Debug)]
    pub enum Event {
        MyEvent: MyEvent,
    }

    #[derive(Drop, starknet::Event, Debug, PartialEq)]
    pub struct MyEvent {
        #[key]
        pub name: ByteArray,
        pub addr: ContractAddress,
    }

    #[abi(embed_v0)]
    impl SimpleImpl of super::ISimple<ContractState> {
        fn emit_event(ref self: ContractState) {
            self.emit(MyEvent { name: "John Doe", addr: get_caller_address() });
        }
    }
}

#[cfg(test)]
mod tests {
    use super::simple_contact;
    use super::{ISimpleDispatcher, ISimpleDispatcherTrait};

    use core::starknet::{ContractAddress, Event, get_caller_address};
    use core::starknet::syscalls::deploy_syscall;

    fn drop_all_events(address: ContractAddress) {
        loop {
            match starknet::testing::pop_log_raw(address) {
                core::option::Option::Some(_) => {},
                core::option::Option::None => { break; },
            };
        }
    }

    #[test]
    fn test_emit_event() {
        let caller = starknet::contract_address_const::<0xdeadbeef>();
        starknet::testing::set_contract_address(caller);

        // deploy contract
        let (contract_address, _) = deploy_syscall(simple_contact::TEST_CLASS_HASH.try_into().unwrap(), 0, [].span(), false).unwrap();

        drop_all_events(contract_address);

        // call emit_event
        let contract = ISimpleDispatcher { contract_address };
        contract.emit_event();

        assert_eq!(
            starknet::testing::pop_log(contract_address),
            Option::Some(simple_contact::MyEvent { addr: caller, name: "John Doe" })
        );
    }
}
