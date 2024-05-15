part of 'welcome.dart';

extension WelcomMobile on WelcomeScreen {
  PreferredSizeWidget appBarMobile() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu_outlined),
        onPressed: model.openMenu,
      ),
      backgroundColor: Colors.green,
      toolbarHeight: kToolbarHeight,
      title: Text(prefs.appTitle()),
      actions: [
        StreamBuilder(
            stream: model.fiscalController.stream,
            builder: (builder, snapshot) {
              return Container(
                  padding: const EdgeInsets.all(10),
                  child: InkWell(
                    onTap: model.changeFiscalMode,
                    child: Image.asset(model.printFiscal
                        ? 'assets/icons/basketball.png'
                        : 'assets/icons/football.png'),
                  ));
            }),
        StreamBuilder(
            stream: model.basketController.stream,
            builder: (builder, snapshot) {
              return Row(children: [
                for (final p1 in model.appdata.part1List()) ...[
                  SizedBox(
                      width: 30,
                      child: p1['f_id'] == model.appdata.part1filter
                          ? Image.asset('assets/icons/finger.png')
                          : Container()),
                  InkWell(
                      onTap: () {
                        model.appdata.loadPart2(p1['f_id']);
                      },
                      child: Container(
                          decoration: BoxDecoration(),
                          child: Text(p1['f_name'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)))),
                  Container(width: 10),
                ],
              ]);
            }),
        //Expanded(child: Container()),
      ],
    );
  }

  Widget bodyMobile() {
    return Column(
      children: [
        Container(
            height: 330,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              //PART 2
              Expanded(
                  child: GestureDetector(
                      onVerticalDragUpdate: (d) {
                        _p1controller.jumpTo(_p1controller.position.pixels -
                            d.delta
                                .dy); //, duration: Duration(milliseconds: 100), curve: Curves.linear);
                      },
                      child: SingleChildScrollView(
                          controller: _p1controller,
                          child: StreamBuilder(
                              stream: model.basketController.stream,
                              builder: (builder, snapshot) {
                                return Column(children: [
                                  for (final e in model.appdata.part2List(
                                      model.appdata.part1filter)) ...[
                                    Part2(e, model)
                                  ],
                                ]);
                              })))),

              //DISHES
              Expanded(
                  child: StreamBuilder(
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final e in model.appdata.dish) ...[
                                    if (e['f_part'] ==
                                        model.appdata.part2filter)
                                      Dish(e, model)
                                  ]
                                ],
                              )),
                        );
                      }))
            ])),

        //BASKET
        Expanded(
            child: Row(children: [
          Expanded(
              child: StreamBuilder(
                  stream: model.basketController.stream,
                  builder: (builder, snapshot) {
                    return Column(children: [
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
                                onPressed: model.processOrder,
                                title: model.tr('Order'))),
                      const SizedBox(
                        height: 5,
                      )
                    ]);
                  }))
        ]))
      ],
    );
  }

  List<Widget> menuWidgetsMobile() {
    return [
      Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: Color(0xff004779),
              border: Border.fromBorderSide(BorderSide(color: Colors.white)),
              borderRadius: BorderRadius.all(Radius.circular(50))),
          child: Text(prefs.string('table'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold))),
      PopupMenuItem(
          child: ListTile(
        leading: SizedBox(
            width: 24,
            height: 24,
            child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.shopping_basket_outlined, color: Colors.white),
              StreamBuilder(
                  stream: model.basketController.stream,
                  builder: (builder, snapshot) {
                    if (model.appdata.basket.isEmpty) {
                      return Container();
                    }
                    return Align(
                        alignment: Alignment.topRight,
                        child: Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text('${model.appdata.basket.length}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold))));
                  })
            ])),
        title: Text(model.tr('Basket'),
            style: const TextStyle(color: Colors.white)),
        onTap: () {
          BlocProvider.of<AppAnimateBloc>(prefs.context())
              .add(AppAnimateEvent());
          model.navBasket();
        },
      )),
      PopupMenuItem(
          child: ListTile(
        leading: const Icon(Icons.settings_outlined, color: Colors.white),
        title: Text(model.tr('Options'),
            style: const TextStyle(color: Colors.white)),
        onTap: () {
          BlocProvider.of<AppAnimateBloc>(prefs.context())
              .add(AppAnimateEvent());
          model.navSettings();
        },
      )),
      PopupMenuItem(
          child: ListTile(
        leading: const Icon(Icons.monitor, color: Colors.white),
        title: Text(model.tr('Process'),
            style: const TextStyle(color: Colors.white)),
        onTap: () {
          BlocProvider.of<AppAnimateBloc>(prefs.context())
              .add(AppAnimateEvent());
          model.navProcess();
        },
      )),
      PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.monitor, color: Colors.white),
            title: Text(model.tr('Cashdesk'),
                style: const TextStyle(color: Colors.white)),
            onTap: () {
              BlocProvider.of<AppAnimateBloc>(prefs.context())
                  .add(AppAnimateEvent());
              model.navCashdesk();
            },
          )),
      if ((prefs.getInt('user_group') ?? 0) == 1)
        PopupMenuItem(
            child: ListTile(
          leading: const Icon(Icons.request_page_outlined, color: Colors.white),
          title: Text(model.tr('Carwash status'),
              style: const TextStyle(color: Colors.white)),
          onTap: () {
            BlocProvider.of<AppAnimateBloc>(prefs.context())
                .add(AppAnimateEvent());
            model.navStatus();
          },
        )),
      PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: Text(model.tr('Logout'), style: const TextStyle(color: Colors.white),),
            onTap: () {
              prefs.setString('passhash', '');
              model.navLogin();
            },
          )),
    ];
  }
}
