import '../bloc/leader_bloc.dart';
import 'user.dart';

class LeaderData {
  final UIState state;
  final List<User> list;
  final String? name;
  final bool networkErr;
  final String? flag;
  final String? id;
  final int silver;
  final int bronze;
  final bool updating;
  final bool signInErr;

  const LeaderData(
      {this.flag,
      this.state = UIState.LOADING,
      this.list = const [],
      this.name,
      this.networkErr = false,
      this.id,
      this.silver = -1,
      this.bronze = -1,
      this.updating = false,
      this.signInErr = false});

  LeaderData copyWith(
          {UIState? state,
          bool? animate,
          List<User>? list,
          String? name,
          bool? networkErr,
          String? flag,
          String? id,
          int? silver,
          int? bronze,
          bool? updating,
          bool? signInErr}) =>
      LeaderData(
          state: state ?? this.state,
          list: list ?? this.list,
          name: name ?? this.name,
          networkErr: networkErr ?? false,
          flag: flag ?? this.flag,
          id: id ?? this.id,
          silver: silver ?? this.silver,
          bronze: bronze ?? this.bronze,
          updating: updating ?? this.updating,
          signInErr: signInErr ?? false);

  @override
  String toString() {
    return 'LeaderData{flag: $flag}';
  }
}
