use scrypto::{runtime::Clock, time::Instant};

pub trait Time {
    fn time_in_seconds() -> u64;
    fn time_in_minutes() -> u64;
    fn instant() -> Instant;
}

impl Time for Clock {
    fn time_in_seconds() -> u64 {
        Clock::current_time_rounded_to_seconds().seconds_since_unix_epoch as u64
    }
    fn time_in_minutes() -> u64 {
        (Clock::current_time_rounded_to_minutes().seconds_since_unix_epoch / 60) as u64
    }
    fn instant() -> Instant {
        Clock::current_time_rounded_to_seconds()
    }
}

pub trait InstantExtended {
    fn minutes(&self) -> u64;
    fn seconds_marginal(&self) -> u64;
}

impl InstantExtended for Instant {
    fn minutes(&self) -> u64 {
        (self.seconds_since_unix_epoch as u64) / 60
    }

    fn seconds_marginal(&self) -> u64 {
        (self.seconds_since_unix_epoch as u64) % 60
    }
}
