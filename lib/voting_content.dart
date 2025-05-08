import 'package:flutter/cupertino.dart';
import 'package:spycast/game_lobby.dart';

class VotingContent extends StatefulWidget {
  final List<dynamic> players;
  final int waitingOnNumPlayers;
  final String userName;
  final void Function(String votedFor) onVote;
  final int? votedFor;

  const VotingContent({
    super.key,
    required this.players,
    required this.waitingOnNumPlayers,
    required this.userName,
    required this.onVote,
    required this.votedFor,
  });

  @override
  State<VotingContent> createState() => _VotingContentState();
}

class _VotingContentState extends State<VotingContent> {
  String? votedFor;

  @override
  void initState() {
    super.initState();
    setState(() {
      votedFor =
          widget.votedFor != null
              ? widget.players[widget.votedFor!]['name']
              : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Icon(
            CupertinoIcons.person_3_fill,
            color: CupertinoColors.white,
            size: 80,
          ),
          const SizedBox(height: 20),
          const Text(
            'Tap a player to vote for the spy\nYou can only vote once!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: CupertinoColors.white),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: widget.players.length,
              itemBuilder: (context, index) {
                final player = widget.players[index];
                final name = player['name'];
                final isSelf = name == widget.userName;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 6,
                  ),
                  child: CupertinoButton(
                    color:
                        votedFor == name
                            ? CupertinoColors.systemIndigo
                            : CupertinoColors.darkBackgroundGray,
                    disabledColor: CupertinoColors.systemGrey,
                    onPressed:
                        isSelf
                            ? null
                            : () {
                              if (votedFor == null) {
                                setState(() {
                                  votedFor = name;
                                });
                                widget.onVote(name);
                              }
                            },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name + (isSelf ? " (You)" : ""),
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 18,
                          ),
                        ),
                        if (votedFor == name)
                          const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: CupertinoColors.white,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: WaitingDots(
              waitingText:
                  'Waiting for ${widget.waitingOnNumPlayers} players to vote',
              style: TextStyle(color: CupertinoColors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
