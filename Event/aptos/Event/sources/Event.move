module Ticketing {
    use std::signer;
    use std::vector;
    use std::string;
    use std::address;
    use std::map;
    use std::option;

    struct Event has store {
        id: u64,
        name: string::String,
        total_tickets: u64,
        tickets_sold: u64,
    }

    struct Ticket has store {
        event_id: u64,
        owner: address::Address,
    }

    struct Account has store {
        tickets: vector::Vector<Ticket>,
    }

    struct EventStore has store {
        events: map::Map<u64, Event>,
    }

    struct AccountStore has store {
        accounts: map::Map<address::Address, Account>,
    }

    public fun initialize() {
        let event_store = EventStore {
            events: map::empty(),
        };
        move_to(&signer::address_of(&signer::borrow_global_mut<signer::Signer>()), event_store);

        let account_store = AccountStore {
            accounts: map::empty(),
        };
        move_to(&signer::address_of(&signer::borrow_global_mut<signer::Signer>()), account_store);
    }

    public fun create_event(
        sender: &signer,
        event_id: u64,
        name: string::String,
        total_tickets: u64,
    ) {
        let event_store = borrow_global_mut<EventStore>(0x1);
        let new_event = Event {
            id: event_id,
            name: name,
            total_tickets: total_tickets,
            tickets_sold: 0,
        };
        map::insert(&mut event_store.events, event_id, new_event);
    }

    public fun purchase_ticket(
        sender: &signer,
        event_id: u64,
    ) {
        let mut event_store = borrow_global_mut<EventStore>(0x1);
        let mut event = map::borrow_mut(&mut event_store.events, event_id);
        assert!(event.tickets_sold < event.total_tickets, 1);
        event.tickets_sold = event.tickets_sold + 1;

        let ticket = Ticket {
            event_id: event_id,
            owner: signer::address_of(sender),
        };

        let mut account_store = borrow_global_mut<AccountStore>(0x1);
        let account_address = signer::address_of(sender);
        let mut account = match map::get_mut(&mut account_store.accounts, account_address) {
            option::Some(mut acc) => acc,
            option::None => {
                let new_account = Account {
                    tickets: vector::empty(),
                };
                map::insert(&mut account_store.accounts, account_address, new_account);
                map::borrow_mut(&mut account_store.accounts, account_address)
            }
        };
        vector::push_back(&mut account.tickets, ticket);
    }

    public fun transfer_ticket(
        sender: &signer,
        ticket_index: u64,
        new_owner: address::Address,
    ) {
        let mut account_store = borrow_global_mut<AccountStore>(0x1);
        let mut account = map::borrow_mut(&mut account_store.accounts, signer::address_of(sender));
        let mut ticket = vector::borrow_mut(&mut account.tickets, ticket_index);
        assert!(ticket.owner == signer::address_of(sender), 2);
        ticket.owner = new_owner;
    }

    public fun get_event(event_id: u64): Event {
        let event_store = borrow_global<EventStore>(0x1);
        match map::get(&event_store.events, event_id) {
            option::Some(event) => event,
            option::None => {
                Event {
                    id: event_id,
                    name: "Event Not Found".to_string(),
                    total_tickets: 0,
                    tickets_sold: 0,
                }
            }
        }
    }

    public fun get_account(account_address: address::Address): Account {
        let account_store = borrow_global<AccountStore>(0x1);
        match map::get(&account_store.accounts, account_address) {
            option::Some(account) => account,
            option::None => {
                Account {
                    tickets: vector::empty(),
                }
            }
        }
    }
}
