import std.stdio;
import std.file;
import std.array;
import std.algorithm;

import sdlang;

import vibe.vibe;

string baseDir = `D:\code`;

void main()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8083;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, &hello);

	logInfo("Please open http://127.0.0.1:8081/ in your browser.");

	extractAppsNames(getSDLFilesList(baseDir));

	runApplication();


}

void hello(HTTPServerRequest req, HTTPServerResponse res)
{
	res.writeBody("Hello, World!");
}

string [] getSDLFilesList(string dir)
{
	return dirEntries(dir, "*.{sdl}",SpanMode.depth).map!(a=>a.name).array;
}

void extractAppsNames(string [] getSDLFilesList)
{
	string [] appsNames;

	Tag root;
	foreach(f; getSDLFilesList)
	{
		auto text = readText(f);
		root = parseSource(text);
		//Tag akiko = root.tag["name"];
		auto name = root.getTagValue!string("name");
		appsNames ~= name;
	}
}

