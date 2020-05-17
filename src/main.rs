use mozjs_example::run_js;
use std::io::{stdin, Stdin};
use smol;

trait LinesTrait: Sized {
    fn lines(self) -> Lines;
}

impl LinesTrait for Stdin {
    fn lines(self) -> Lines { Lines { r: self } }
}

struct Lines {
    r: Stdin,
}

impl Iterator for Lines {
    type Item = String;
    fn next(&mut self) -> Option<String> {
        let mut ret_val = String::new();
        self.r.read_line(&mut ret_val).ok()?;
        if ret_val == "" { None } else { Some(ret_val) }
    }
}

fn main() {
    let i = stdin().lines();
    smol::run(run_js(i));
}

