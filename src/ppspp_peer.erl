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

-module(ppspp_peer).
-include("swirl.hrl").

-export([start/1, stop/1, handle_packet_sync/4]).

stop(_Peer) ->
    % TODO assuming _Peer is actually going to be Port instead
    % loop over open channels
    % close them
    % shut down ets tables
    ok.

start(Port) ->
    {ok, Socket} = gen_udp:open(Port, [binary, {active, false} ]),
    ?DEBUG_SWIRL("peer: listening on udp", Port),
    loop(Socket).

loop(Socket) ->
    inet:setopts(Socket, [{active, once}]),
    receive
        %% TODO maybe its more efficient to pass {udp, ...} along already
        %% packed up into something sensible, tuple or orddict.
        {udp, Socket, Peer, Port, << Maybe_Datagram/binary >> } ->
            handle_packet_async(udp, Peer, Port, Maybe_Datagram),
            loop(Socket)
    end.

handle_packet_async(udp, Peer, Port, Maybe_Datagram) ->
    spawn(?MODULE, handle_packet_sync, [udp, Peer, Port, Maybe_Datagram]).

handle_packet_sync(udp, Peer, Port, Maybe_Datagram ) ->
    %% TODO move this to handle_cast/async to
    %% avoid refc binaries and increase throughput
    Endpoint = ?ENDPOINT2STR(Peer, Port),
    ?DEBUG_SWIRL("peer: recv udp from", Endpoint),
    Transport = orddict:from_list([ {peer, Peer},
                                    {port, Port},
                                    {endpoint, Endpoint},
                                    {transport, udp}]),
    {ok, Datagram} = ppspp_datagram:unpack(Transport, Maybe_Datagram),
    %% TODO it might make more sense to return some info and
    %% keep some useful state here
    {ok, _State} = ppspp_datagram:handle(Datagram).