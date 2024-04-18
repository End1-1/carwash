part of "process.dart";

extension ProcessMobile on _BodyState {

  Widget bodyMobile() {
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
          return //ORDERS
            Expanded(
                child: SingleChildScrollView(
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
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
                ),




                for (final o in snapshot.data ?? []) ...[
                  if (o['progress'] == 1) ...[
                    pendingWidget(o),
                    const Divider(
                        color: Colors.white,
                        height: 2,
                        thickness: 2)
                  ]
                ],


                Container(
                  width: double.infinity,
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
                ),


                                            for (final o in snapshot.data ?? []) ...[
                                              if (o['progress'] > 1) ...[
                                                processWidget(o),
                                                const Divider(
                                                    color: Colors.white,
                                                    height: 2,
                                                    thickness: 2)
                                              ]
                                            ],



                                      ])));});
  }
}