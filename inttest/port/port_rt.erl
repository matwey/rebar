%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et

-module(port_rt).
-export([files/0,
         run/1]).

-include_lib("eunit/include/eunit.hrl").

files() ->
    [
     {copy, "../../rebar", "rebar"},
     {copy, "rebar.config", "rebar.config"},
     {copy, "c_src", "c_src"},
     {create, "ebin/foo.app", app(foo, [])}
    ].

run(_Dir) ->
    % wait a bit for new files to have different timestamps
    wait(),
    % test.so is created during first compile
    ?assertEqual(0, filelib:last_modified("priv/test.so")),
    ?assertMatch({ok, _}, retest_sh:run("./rebar compile", [])),
    TestSo1 = filelib:last_modified("priv/test.so"),
    ?assert(TestSo1 > 0),
    wait(),
    % nothing happens during second compile
    ?assertMatch({ok, _}, retest_sh:run("./rebar compile", [])),
    TestSo2 = filelib:last_modified("priv/test.so"),
    Test1o2 = filelib:last_modified("c_src/test1.o"),
    Test2o2 = filelib:last_modified("c_src/test2.o"),
    ?assertEqual(TestSo1, TestSo2),
    ?assert(TestSo1 >= Test1o2),
    ?assert(TestSo1 >= Test2o2),
    wait(),
    % when test2.c changes, at least test2.o and test.so are rebuilt
    ?assertMatch({ok, _}, retest_sh:run("touch c_src/test2.c", [])),
    ?assertMatch({ok, _}, retest_sh:run("./rebar compile", [])),
    TestSo3 = filelib:last_modified("priv/test.so"),
    Test2o3 = filelib:last_modified("c_src/test2.o"),
    ?assert(TestSo3 > TestSo2),
    ?assert(Test2o3 > TestSo2),
    wait(),
    % when test2.h changes, at least test2.o and test.so are rebuilt
    ?assertMatch({ok, _}, retest_sh:run("touch c_src/test2.h", [])),
    ?assertMatch({ok, _}, retest_sh:run("./rebar compile", [])),
    TestSo4 = filelib:last_modified("priv/test.so"),
    Test2o4 = filelib:last_modified("c_src/test2.o"),
    ?assert(TestSo4 > TestSo3),
    ?assert(Test2o4 > TestSo3),
    wait(),
    % when test1.h changes, everything is rebuilt
    ?assertMatch({ok, _}, retest_sh:run("touch c_src/test1.h", [])),
    ?assertMatch({ok, _}, retest_sh:run("./rebar compile", [])),
    TestSo5 = filelib:last_modified("priv/test.so"),
    Test1o5 = filelib:last_modified("c_src/test1.o"),
    Test2o5 = filelib:last_modified("c_src/test2.o"),
    ?assert(TestSo5 > TestSo4),
    ?assert(Test1o5 > TestSo4),
    ?assert(Test2o5 > TestSo4),
    ok.

wait() ->
    timer:sleep(1000).

%%
%% Generate the contents of a simple .app file
%%
app(Name, Modules) ->
    App = {application, Name,
           [{description, atom_to_list(Name)},
            {vsn, "1"},
            {modules, Modules},
            {registered, []},
            {applications, [kernel, stdlib]}]},
    io_lib:format("~p.\n", [App]).
