import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:futuristic/futuristic.dart';

import 'package:Argo/main.dart';
import 'package:Argo/src/layout.dart';
import 'package:Argo/src/utils/hive/adapters.dart';
import 'package:Argo/src/ui/CustomWidgets.dart';

class Cijfers extends StatefulWidget {
  @override
  _Cijfers createState() => _Cijfers();
}

class _Cijfers extends State<Cijfers> {
  DateFormat formatDate = DateFormat("dd-MM-y");
  int jaar = 0;
  @override
  Widget build(BuildContext context) {
    List<Periode> perioden = account.cijfers[jaar].perioden
        .where(
          (periode) => account.cijfers[jaar].cijfers.where((cijfer) => cijfer.periode.id == periode.id).isNotEmpty,
        )
        .toList();

    return ValueListenableBuilder(
      valueListenable: updateNotifier,
      builder: (BuildContext context, _, _a) {
        return DefaultTabController(
          length: jaar == 0 ? 1 + perioden.length : perioden.length,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.menu,
                ),
                onPressed: () {
                  DrawerStates.layoutKey.currentState.openDrawer();
                },
              ),
              bottom: TabBar(
                isScrollable: true,
                tabs: [
                  if (jaar == 0) // Recenst
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: Tab(
                        text: "Recent",
                      ),
                    ),
                  for (Periode periode in perioden)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: Tab(
                        text: periode.abbr,
                      ),
                    ),
                ],
              ),
              title: PopupMenuButton(
                initialValue: jaar,
                onSelected: (value) => setState(() => jaar = value),
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry>[
                    for (int i = 0; i < account.cijfers.length; i++)
                      PopupMenuItem(
                        value: i,
                        child: Text('${account.cijfers[i].leerjaar}'),
                      ),
                  ];
                },
                child: Row(
                  children: [
                    Text("Cijfers - ${account.cijfers[jaar].leerjaar}"),
                    Icon(Icons.keyboard_arrow_down_outlined),
                  ],
                ),
              ),
            ),
            body: TabBarView(
              children: [
                if (jaar == 0) // Recenst
                  RefreshIndicator(
                    onRefresh: () async {
                      await handleError(account.magister.cijfers.refresh, "Kon cijfers niet verversen", context);
                    },
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: account.recenteCijfers.isEmpty
                          ? Center(
                              child: Text("Nog geen cijfers"),
                            )
                          : SeeCard(
                              column: [
                                for (Cijfer cijfer in account.recenteCijfers)
                                  Container(
                                    child: CijferTile(cijfer, isRecent: true),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: greyBorderSide(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                for (Periode periode in perioden)
                  RefreshIndicator(
                    onRefresh: () async {
                      await handleError(account.magister.cijfers.refresh, "Kon cijfers niet verversen", context);
                    },
                    child: SingleChildScrollView(
                      child: SeeCard(
                        column: () {
                          List cijfersInPeriode = account.cijfers[jaar].cijfers
                              .where(
                                (cijfer) => cijfer.periode.id == periode.id,
                              )
                              .toList();

                          return [
                            for (Cijfer cijfer in cijfersInPeriode)
                              ListTileBorder(
                                border: Border(
                                  left: greyBorderSide(),
                                  bottom: cijfersInPeriode.last == cijfer
                                      ? BorderSide(
                                          width: 0,
                                          color: Colors.transparent,
                                        )
                                      : greyBorderSide(),
                                ),
                                title: Text("${cijfer.vak.naam}"),
                                subtitle: Text("${formatDate.format(cijfer.ingevoerd)}"),
                                trailing: CircleShape(
                                  child: Text(
                                    "${cijfer.cijfer}",
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CijferPagina(cijfer.vak.id, jaar),
                                    ),
                                  );
                                },
                              ),
                          ];
                        }(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CijferPagina extends StatefulWidget {
  final int id;
  final int jaar;
  CijferPagina(this.id, this.jaar);
  @override
  _CijferPagina createState() => _CijferPagina(id, jaar);
}

class _CijferPagina extends State<CijferPagina> {
  CijferJaar jaar;
  List<Cijfer> cijfers;
  Vak vak;
  double doubleCijfers;
  List<double> avgCijfers;
  double totalWeging;
  _CijferPagina(int id, int jaar) {
    this.jaar = account.cijfers[jaar];
    this.cijfers = this.jaar.cijfers.where((cijfer) => cijfer.vak.id == id).toList();
    this.vak = cijfers.first.vak;
    avgCijfers = [];
    doubleCijfers = 0;
    totalWeging = 0;
    cijfers.reversed.forEach(
      (Cijfer cijfer) {
        if (cijfer.weging == 0 || cijfer.weging == null) return;
        double cijf;
        try {
          cijf = double.parse(cijfer.cijfer.replaceFirst(",", "."));
        } catch (e) {}
        if (cijf != null) {
          doubleCijfers += cijf * cijfer.weging;
          totalWeging += cijfer.weging;
          avgCijfers.add(doubleCijfers / totalWeging);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          vak.naam,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.flag,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.calculate,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (avgCijfers.isNotEmpty)
              SizedBox(
                height: 200.0,
                child: charts.LineChart(
                  _createCijfers(),
                ),
              ),
            for (Periode periode in jaar.perioden)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: () {
                  List<Cijfer> periodecijfers = cijfers
                      .where(
                        (cijf) => cijf.periode.id == periode.id,
                      )
                      .toList();
                  if (periodecijfers.isEmpty)
                    return <Widget>[];
                  else
                    return [
                      ContentHeader(periode.naam),
                      SeeCard(
                        column: [
                          for (Cijfer cijfer in periodecijfers)
                            Futuristic(
                              autoStart: true,
                              futureBuilder: () => account.magister.cijfers.getExtraInfo(cijfer, jaar),
                              busyBuilder: (context) => CircularProgressIndicator(),
                              errorBuilder: (context, error, retry) {
                                return Text("Error $error");
                              },
                              dataBuilder: (context, data) => CijferTile(
                                cijfer,
                                border: periodecijfers.last != cijfer
                                    ? Border(
                                        bottom: greyBorderSide(),
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ];
                }(),
              ),
          ],
        ),
      ),
    );
  }

  List<charts.Series<double, int>> _createCijfers() {
    return [
      new charts.Series<double, int>(
        id: 'Cijfers',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (double cijfer, i) => i,
        measureFn: (double cijfer, _) => cijfer,
        displayName: "Gemiddelde",
        data: avgCijfers,
      )
    ];
  }
}
