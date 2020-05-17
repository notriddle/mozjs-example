#![allow(
    non_upper_case_globals,
    non_camel_case_types,
    non_snake_case,
    improper_ctypes
)]

use std::ptr;
use std::ffi::CStr;
use mozjs::jsapi::{OnNewGlobalHookOption, JS_NewGlobalObject, JSContext, Value};
use mozjs::jsval::UndefinedValue;
use mozjs::rooted;
use mozjs::rust::Handle;
use mozjs::rust::SIMPLE_GLOBAL_CLASS;
use mozjs::rust::{JSEngine, RealmOptions, Runtime};
use mozjs::rust::get_object_class;
use mozjs::rust::wrappers::EncodeStringToUTF8;

pub async fn run_js<I: Iterator<Item=String>>(i: I) {
    let engine = JSEngine::init().expect("failed to initalize JS engine");

    let rt = Runtime::new(engine.handle());
    assert!(!rt.cx().is_null(), "failed to create JSContext");

    let cx = rt.cx();
    let options = RealmOptions::default();
    rooted!(in(cx) let global = unsafe {
        JS_NewGlobalObject(cx, &SIMPLE_GLOBAL_CLASS, ptr::null_mut(),
                           OnNewGlobalHookOption::FireOnNewGlobalHook,
                           &*options)
    });

    // for diagnostics
    let filename: &'static str = "inline.js";
    let mut lineno: u32 = 1;

    // return value
    rooted!(in(rt.cx()) let mut rval = UndefinedValue());

    // the final REPL
    for source in i {

        let res = rt.evaluate_script(global.handle(), &source[..], filename, lineno, rval.handle_mut());

        if !res.is_ok() {
            println!("failed to evaluate script");
            continue;
        }

        unsafe { jsvalue_debug(cx, rval.get()); }

        lineno += 1;
    }
}

pub unsafe fn jsvalue_debug(cx: *mut JSContext, r: Value) {
    if r.is_string() {
        EncodeStringToUTF8(cx, Handle::new(&r.to_string()), |cstr| {
            println!("{:?}", CStr::from_ptr(cstr));
        });
    } else if r.is_int32() {
       println!("{:?}", r.to_int32())
    } else if r.is_number() {
        println!("{:?}", r.to_number())
    } else if r.is_boolean() {
        println!("{:?}", r.to_boolean())
    } else if r.is_null() {
        println!("null")
    } else if r.is_undefined() {
        println!("undefined")
    } else if r.is_double() {
        println!("{:?}", r.to_double())
    } else if r.is_object() {
        println!("[object {:?}]", CStr::from_ptr(get_object_class(r.to_object()).as_ref().expect("objects will have classes if they're objects").name))
    } else {
        println!("[object Object]")
    }
}

