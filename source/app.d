import std.stdio;
import std.file;
import std.array;
import std.algorithm;
import std.process;
import std.uni;
import std.path;
import std.range;

import resusage;
import sdlang;
import vibe.vibe;
import globals;

string baseDir = `D:\code`;
string appName = "firefox";

void main()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8083;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, &hello);

	logInfo("Please open http://127.0.0.1:8083/ in your browser.");

	checkIfSDLAppsIsAlreadyRun(extractAppsFullNamesWithPath(getSDLFilesList(baseDir)));
	int appPid = getProcessPIDByAppName(appName);
	if(appPid == 0)
	{
		writefln("Process: %s do not exists in memory", appName);
		return;
	}
	//checkIfPidisAlive(appPid);
	getProcessInfo(appPid);

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

string [] extractAppsFullNamesWithPath(string [] getSDLFilesList) // should return FullNames with path
{
	string [] appsFullPathBaseOnSDL;

	Tag root;
	foreach(f; getSDLFilesList)
	{
		auto text = readText(f);
		root = parseSource(text);
		//Tag akiko = root.tag["name"];
		string appName = root.getTagValue!string("name").toLower;
		appsFullPathBaseOnSDL ~= buildPath(f.dirName, appName); // return ready to run path: D:\code\dlang.ru\dcms
	}
	return appsFullPathBaseOnSDL;
}

// extracting process ID by name
int getProcessPIDByAppName(string appName) // if >0 than process alive
{
	auto process = execute(["tasklist", "/v", "/fo", "csv"]);
	int appPid;

	string result; 
	if (process.status != 0) 
		writeln("Compilation failed:\n", process.output);
	else
	{
		//writeln("Done:\n", process.output);
		result = process.output;
	}

	foreach(line; result.splitLines().dropOne) // first line in cyrillic
	{
		if((line.split(",")[0].replace(`"`,``).stripExtension.toLower) == appName) // [0] - name, [1] - ID
			//writeln(line.split(",")[1]);
		{
			appPid = to!int(line.split(",")[1].replace(`"`,``));
			writeln("Founded PID: ", appPid);
		}

	}

	if(appPid == 0)
	{
		//writeln("Can't find PID. Pid is: ", appPid);
	}

	return appPid;
}

void getProcessInfo(int appPid)
{
	AppMetrics appMetrics;

	auto memInfo = processMemInfo(appPid);
	auto cpuWatcher = new ProcessCPUWatcher(appPid);

	appMetrics.physicalMemory = memInfo.usedVirtMem/1050578;
	appMetrics.cpuUsage = cpuWatcher.current();

	//writeln("Virtual memory used by process: ", memInfo.usedVirtMem);
	//writeln("Physical memory used by process: ", memInfo.usedRAM);
	writeln("Memory: ", appMetrics.physicalMemory);
	writeln("CPU: ", appMetrics.cpuUsage);
}

bool checkIfPidisAlive(int appPid)
{
	bool isAppAlive;
	auto process = execute(["tasklist", "/v", "/fo", "csv"]);

	string result; 
	if (process.status != 0) 
		writeln("Compilation failed:\n", process.output);
	else
	{
		//writeln("Done:\n", process.output);
		result = process.output;
	}

	foreach(line; result.splitLines())
	{
		if((line.split(",")[1]).canFind(appPid)) // preven simillar names like: skype and skypehost
		//writeln(line.split(",")[1]);
		{
			appPid = to!int(line.split(",")[1].replace(`"`,``));
			isAppAlive = true;
		}
	}

	//writefln("Process with PID: %s alive", appPid);
	return isAppAlive;
}

void checkIfSDLAppsIsAlreadyRun(string [] appsFullPathBaseOnSDL) // if already some process run
{
	foreach(app; appsFullPathBaseOnSDL)
	{
		int appPid = getProcessPIDByAppName(app.baseName);
		if(appPid>0) // without baseName contains fullPath
		{
			writefln(`Process "%s" is alread running. PID: %s`, app.baseName, appPid);
		}
		else
		{
			writefln(`Process "%s" DO NOT run. PID: %s`, app.baseName, appPid);	
		}
	}
}