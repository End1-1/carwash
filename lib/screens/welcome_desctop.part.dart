part of 'welcome.dart';

extension WelcomeDesktop on WelcomeScreen {

  PreferredSizeWidget appBarDesktop() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.home_outlined),
        onPressed: model.navHome,
      ),
      backgroundColor: Colors.green,
      toolbarHeight: kToolbarHeight,
      title: Text(prefs.appTitle()),
      actions: [
        StreamBuilder(stream: model.fiscalController.stream, builder: (builder, snapshot) {
          return Container(padding: const EdgeInsets.all(10), child: InkWell(
            onTap: model.changeFiscalMode,
            child: Image.asset(model.printFiscal ? 'assets/icons/basketball.png' : 'assets/icons/football.png'),
          ));
        }),
        StreamBuilder(stream: model.basketController.stream, builder: (builder, snapshot) {return Row(children: [
          for (final p1 in model.appdata.part1List()) ...[
            SizedBox(
                width: 30,
                child: idEq(p1['f_id'], model.appdata.part1filter) ?
                Image.asset('assets/icons/finger.png')
                    : Container()),
            InkWell(
                onTap: () {
                  model.appdata.loadPart2(p1['f_id']);
                },
                child: Container(
                    decoration: const BoxDecoration(
                    ),
                    child: Text((Map<String, dynamic>.from(p1)['f_name']),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)))),
            Container(width: 10),
          ],
        ]);}),
        //Expanded(child: Container()),
        Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Color(0xff004779),
                border: Border.fromBorderSide(BorderSide(color: Colors.white)),
                borderRadius: BorderRadius.all(Radius.circular(50))
            ),
            child: Text(prefs.string('table'),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        TextButton.icon(
          onPressed: () {
            BlocProvider.of<AppAnimateBloc>(prefs.context())
                .add(AppAnimateEvent());
            model.navHistoryGoodsProcess();
          },
          icon: const Icon(Icons.history_outlined, color: Colors.white),
          label: Text(
            model.locale().currentOrders,
            style: const TextStyle(color: Colors.white),
          ),
        ),

        PopupMenuButton(
          icon: const Icon(Icons.settings_outlined),
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(model.locale().options),
                    onTap: model.navSettings,
                  )),
              PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.monitor),
                    title: Text(model.locale().cashdesk),
                    onTap: () {
                      BlocProvider.of<AppAnimateBloc>(prefs.context())
                          .add(AppAnimateEvent());
                      model.navCashdesk();
                    },
                  )),
              PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.history_outlined),
                    title: Text(model.locale().history),
                    onTap: () {
                      BlocProvider.of<AppAnimateBloc>(prefs.context())
                          .add(AppAnimateEvent());
                      model.navHistory();
                    },
                  )),
              if ((prefs.getInt('user_group') ?? 0) == 1)
                PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.request_page_outlined),
                      title: Text(model.locale().carwashStatus),
                      onTap: () {
                        BlocProvider.of<AppAnimateBloc>(prefs.context())
                            .add(AppAnimateEvent());
                        model.navStatus();
                      },
                    )),
              PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(model.locale().logout),
                    onTap: () {
                      prefs.setString('passhash', '');
                      model.navLogin();
                    },
                  )),
            ];
          },
        )
      ],
    );
  }

  Widget bodyDesktop() {
    return Column(
      children: [

        Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              //PART 2
              GestureDetector(
                  onVerticalDragUpdate: (d) {
                    _p1controller.jumpTo(_p1controller.position.pixels - d.delta
                        .dy); //, duration: Duration(milliseconds: 100), curve: Curves.linear);
                  },
                  child: SingleChildScrollView(
                      controller: _p1controller,
                      child: StreamBuilder(
                          stream: model.basketController.stream,
                          builder: (builder, snapshot) {
                            return Column(children: [
                              for (final e in model.appdata
                                  .part2List(model.appdata.part1filter)) ...[
                                Part2(e, model)
                              ],
                            ]);
                          }))),

              //DISHES
              StreamBuilder(
                  stream: model.dishesController.stream,
                  builder: (builder, snapshot) {
                    return GestureDetector(
                        onVerticalDragUpdate: (d) {
                          _d1controller.jumpTo(_d1controller.position.pixels -
                              d.delta
                                  .dy); //, duration: Duration(milliseconds: 100), curve: Curves.linear);
                        },
                        child: SingleChildScrollView(
                          controller: _d1controller,
                          child: Container(
                              width: 400,
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.start,
                                direction: Axis.horizontal,
                                children: [
                                  for (final e in model.appdata.dish) ...[
                                    if (idEq(e['f_part'],
                                        model.appdata.part2filter))
                                      Dish(e, model)
                                  ]
                                ],
                              )),
                        ));
                  }),

              //BASKET
              StreamBuilder(
                  stream: model.basketController.stream,
                  builder: (builder, snapshot) {
                    return Container(
                        width: 400,
                        child: Column(children: [
                          Expanded(
                              child: SingleChildScrollView(
                                child: Wrap(runSpacing: 5, children: [
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  for (final b in model.appdata.basket) ...[
                                    DishBasket(b, model, false),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                  ],
                                ]),
                              )),
                          Payment(model.appdata.basketData, model),
                          const SizedBox(
                            height: 5,
                          ),
                          if (model.appdata.basket.isNotEmpty)
                            Container(
                                height: kButtonHeight,
                                alignment: Alignment.center,
                                child: globalOutlinedButton(
                                    onPressed: () {
                                      if (model.isOrderBusy) return;
                                      model.processOrder();
                                    },
                                    title: model.locale().order),
                                  ),
                          const SizedBox(
                            height: 5,
                          )
                        ]));
                  })
            ]))
      ],
    );
  }
}