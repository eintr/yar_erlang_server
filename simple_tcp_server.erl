-module(simple_tcp_server).

-export([create/2]).

-export([thr_monitor/2, thr_worker/2, accept_loop/2, worker_wrapper/2]).

-author("牛海青").

%-include_lib("kernel/include/file.hrl").

create(Port, {_, ServerFunction}=CallBack) when is_number(Port), is_atom(ServerFunction) ->
	spawn(?MODULE, thr_monitor, [Port, CallBack]).

thr_monitor(Port, CallBack) ->
	io:format("Monitor thread created.~n", []),
	Pid_worker = spawn_link(?MODULE, thr_worker, [Port, CallBack]),
	io:format("Worker thread created.~n", []),
	monitor(process, Pid_worker),
	thr_monitor_loop(Pid_worker, {Port, CallBack}).

thr_monitor_loop(Pid_worker, {Port, CallBack}) ->
	receive
		{'DOWN', _, process, _Pid, _Info} ->
			Pid_worker2 = spawn_link(?MODULE, thr_worker, [Port, CallBack]),
			io:format("Worker thread recreated.~n", []),
			thr_monitor_loop(Pid_worker2, {Port, CallBack});
		{'EXIT', _Pid, Reason} ->
			io:format("Worker thread exit normally: ~p.~n", [Reason]),
			exit(Reason);
		kill ->
			Pid_worker ! {'EXIT', self(), "Normal exit."},
			thr_monitor_loop(Pid_worker, {Port, CallBack});
		Msg ->
			io:format("Unknown message: ~p .~n", [Msg]),
			thr_monitor_loop(Pid_worker, {Port, CallBack})
	end.

thr_worker(Port, CallBack) when is_number(Port) ->
	{ok, ListenSocket} = gen_tcp:listen(Port, [{reuseaddr, true}, {packet, 0}, {active, false}, binary]),
	io:format("ListenSocket created.~n", []),
	accept_loop(ListenSocket, CallBack).	% Never return.

accept_loop(ListenSocket, {Module, ServerFunction}=CallBack) ->
	{ok, ClientSocket} = gen_tcp:accept(ListenSocket),
	{ok, {A, P}} = inet:peername(ClientSocket),
	io:format("Got a connection: ~p:~p~n", [A, P]),
	io:format("spawn(~p, ~p)~n", [Module, ServerFunction]),
	Pid = spawn_link(?MODULE, worker_wrapper, [CallBack, ClientSocket]),
	gen_tcp:controlling_process(ClientSocket, Pid),
	accept_loop(ListenSocket, CallBack).

worker_wrapper({Module, ServerFunction}, ClientSocket) ->
	Module:ServerFunction(ClientSocket),
	gen_tcp:close(ClientSocket).

