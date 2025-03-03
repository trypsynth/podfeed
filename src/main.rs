use regex::Regex;
use reqwest::blocking::get;
use serde::{Deserialize, Serialize};
use std::{env, error::Error, io::Read, process};

#[derive(Deserialize, Serialize, Debug)]
struct Results {
    results: Vec<ResultItem>,
}

#[derive(Deserialize, Serialize, Debug)]
struct ResultItem {
    #[serde(rename = "feedUrl")]
    feed_url: String,
}

fn main() -> Result<(), Box<dyn Error>> {
    if env::args().len() != 2 {
        eprintln!("Usage: {} <URL>", env::args().next().unwrap());
        process::exit(1);
    }
    let url = env::args().nth(1).unwrap();
    let re = Regex::new(r"[^w]+\/id(?P<id>\d+)")?;
    let captures = re.captures(&url).ok_or("No match found for ID")?;
    let id = captures.name("id").ok_or("No ID captured")?.as_str();
    let api_url = format!("https://itunes.apple.com/lookup?id={}&entity=podcast", id);
    let mut response = get(&api_url)?;
    let mut body = String::new();
    response.read_to_string(&mut body)?;
    let response: Results = serde_json::from_str(&body)?;
    println!("{}", response.results[0].feed_url);
    Ok(())
}
