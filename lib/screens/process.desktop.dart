part of "process.dart";

extension ProcessDesktop on _BodyState {

  Widget bodyDesktop() {
    return StreamBuilder(
        stream: widget.model.basketController.stream,
        builder: (builder, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data is int) {
            return const Center(child: CircularProgressIndicator());
          }
          pending = 0;
          inProgress = 0;
          for (final o in snapshot.data) {
            if (o['progress'] > 1) {
              if (o['progress'] < 4) {
                inProgress++;
              }
            } else {
              pending++;
            }
          }
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.blueAccent, Colors.blue])),
                        child: Text(
                          '${widget.model.tr('In progress')} $inProgress',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      )),
                  Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.deepOrange, Colors.orange])),
                        child: Text(
                          '${widget.model.tr('Pending')} $pending',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ))
                ]),
                //ORDERS
                Expanded(
                    child: SingleChildScrollView(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: Container(
                                      color: Colors.blue,
                                      child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                          children: [
                                            for (final o in snapshot.data ?? []) ...[
                                              if (o['progress'] > 1) ...[
                                                processWidget(o),
                                                const Divider(
                                                    color: Colors.white,
                                                    height: 2,
                                                    thickness: 2)
                                              ]
                                            ],
                                          ]))),
                              Expanded(
                                  child: Container(
                                      color: Colors.orange,
                                      child: Column(children: [
                                        for (final o in snapshot.data ?? []) ...[
                                          if (o['progress'] == 1) ...[
                                            pendingWidget(o),
                                            const Divider(
                                                color: Colors.white,
                                                height: 2,
                                                thickness: 2)
                                          ]
                                        ]
                                      ]))),
                            ])))
              ]);
        });
  }

}