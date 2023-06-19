import '../bloc/leader_bloc.dart';

class Event {
  final Cmd cmd;
  final String? flag;

  Event(this.cmd, [this.flag]);
}
