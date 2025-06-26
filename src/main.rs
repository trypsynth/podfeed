#![warn(clippy::all, clippy::pedantic, clippy::nursery)]

use anyhow::{Context, Result};
use regex::Regex;
use reqwest::blocking::Client;
use serde::Deserialize;
use std::env;

#[derive(Deserialize, Debug)]
struct ItunesResponse {
	results: Vec<PodcastResult>,
}

#[derive(Deserialize, Debug)]
struct PodcastResult {
	#[serde(rename = "feedUrl")]
	feed_url: String,
}

fn extract_podcast_id(url: &str) -> Result<String> {
	let re = Regex::new(r"/id(?P<id>\d+)").context("Failed to compile regex")?;
	let id =
		re.captures(url).and_then(|caps| caps.name("id")).map(|m| m.as_str()).context("No podcast ID found in URL")?;
	Ok(id.to_string())
}

fn fetch_feed_url(podcast_id: &str) -> Result<String> {
	let client = Client::new();
	let api_url = format!("https://itunes.apple.com/lookup?id={podcast_id}&entity=podcast");
	let response: ItunesResponse = client
		.get(&api_url)
		.send()
		.context("Failed to send request")?
		.json()
		.context("Failed to parse JSON response")?;
	response.results.first().map(|result| result.feed_url.clone()).context("No podcast found with the given ID")
}

fn main() -> Result<()> {
	let url = env::args().nth(1).context("Usage: program <iTunes_URL>")?;
	let podcast_id = extract_podcast_id(&url)?;
	let feed_url = fetch_feed_url(&podcast_id)?;
	println!("{feed_url}");
	Ok(())
}
