%% -*- tab-width: 4;erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ft=erlang ts=4 sw=4 et
% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

%% @doc Library for PPSPP over UDP, aka Swift protocol
%% <p>Wrapper to support running directly from escript.</p>
%% @end

-module(swirl).
-include("swirl.hrl").

-ifdef(TEST).
-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").
-endif.

-export([main/1,
        start_peer/0,
        start_peer/1,
        start_peers/1,
        stop_peer/0,
        stop_peer/1,
        stop_peers/1,
         start/0]).

%% for erl and swirl from terminal
start() ->
    {ok, _} = application:ensure_all_started(?MODULE),
    ok.

start_peer() ->
    start_peer(?SWIRL_PORT).
start_peer(Port) when is_integer(Port), Port > 0, Port < 65535 ->
    supervisor:start_child(peer_sup, [Port]).

start_peers(Ports) when is_list(Ports) ->
    lists:map(fun(Port) -> start_peer(Port) end, Ports).

stop_peer() ->
    stop_peer(?SWIRL_PORT).
stop_peer(Port) when is_integer(Port), Port > 0, Port < 65535 ->
    Worker_pid = whereis(convert:port_to_atom(Port)),
    supervisor:terminate_child(peer_sup, Worker_pid).

stop_peers(Ports) when is_list(Ports) ->
    lists:map(fun(Port) ->
            {stop_peer(Port), Port} end,
        Ports).

%% for escript support
main(_) ->
    start(),
    start_peer(),
    ?INFO("^C to exit~n", []),
    timer:sleep(infinity).