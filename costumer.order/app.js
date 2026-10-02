(function () {
  "use strict";


  var STORAGE_KEY = "carwash_site_v2";
  var DEFAULT_MENU = parseInt(getQueryParam("menu") || "1", 10) || 1;
  var CONTACT_PHONE = getQueryParam("phone") || "+374 95 055838";
  var CONTACT_EMAIL = getQueryParam("email") || "info@hyusisayin-carwash.am";

  var V = {
    HOME: "home",
    VISIT: "visit",
    MENU: "menu",
    CHECKOUT: "checkout",
    PAYMENT: "payment",
    ORDERS: "orders",
    PROFILE: "profile",
    TERMS: "terms",
    CANCELLATION: "cancellation",
    PRIVACY: "privacy",
    SUCCESS: "success"
  };

  var LEGAL_PATHS = {
    terms: "terms",
    cancellation: "cancellation",
    privacy: "privacy",
    policy: "privacy"
  };

  var COMPANY_TIN = "02853428";
  var COMPANY_SITE = "hyusisayin-carwash.am";

  var LANGS = ["hy", "ru", "en"];

  var I18N = {
    hy: {
      chooseCar: "Ընտրեք ավտոմեքենա",
      chooseBrand: "Ընտրեք մակնիշը",
      chooseModel: "Ընտրեք մոդելը",
      filterPlaceholder: "Մուտքագրեք որոնման համար…",
      clear: "Մաքրել",
      customOption: "Իմ տարբերակը",
      customLabel: "Ձեր մեքենան",
      youSelected: "Դուք ընտրել եք",
      noModels: "Մոդելներ չկան",
      chooseType: "Ընտրեք տիպը",
      sedan: "Սեդան",
      crossover: "Քրոսովեր",
      suv: "Անհատ",
      next: "Հաջորդ",
      services: "Ծառայություններ",
      tapToAdd: "Սեղմեք՝ զամբյուղում ավելացնելու համար",
      added: "Ավելացվեց",
      cart: "Զամբյուղ",
      total: "Ընդամենը",
      checkout: "Պատվերի ձևակերպում",
      goPay: "Անցնել վճարման",
      pay: "Վճարել",
      phone: "Հեռախոս",
      name: "Անուն",
      sendOtp: "Ուղարկել կոդ",
      otp: "SMS կոդ",
      login: "Մուտք",
      orders: "Պատվերներ",
      activeOrders: "Գործող պատվերներ",
      historyOrders: "Պատմություն",
      noOrders: "Պատվերներ չկան",
      thankYou: "Շնորհակալություն!",
      orderAccepted: "Պատվերը ընդունված է",
      newOrder: "Նոր պատվեր",
      loading: "Բեռնվում է…",
      emptyCart: "Զամբյուղը դատարկ է",
      statusActive: "Աктивный",
      statusDone: "Կատարված",
      statusCancelled: "Չեղարկված",
      menuErr: "Մենյու",
      back: "Հետ",
      changePhone: "Փոխել հեռախոսը",
      resendOtp: "Կրկին ուղարկել կոդ",
      resendIn: "Կրկին ուղարկել ({n} վ)",
      profileTitle: "Անձնական տվյալներ",
      account: "Ակաունտ",
      langHy: "Հայերեն",
      langRu: "Русский",
      langEn: "English",
      logout: "Ելք",
      navTerms: "Օգտագործման պայմաններ",
      navCancellation: "Չեղարկման քաղաքականություն",
      navPrivacy: "Գաղտնիության քաղաքականություն",
      acceptedCards: "Ընդունվող քարտեր",
      contactsTitle: "Կոնտակտներ",
      companyName: "«Սմարտ Պարկինգ» ՍՊԸ (Smart Parking LLC)",
      tinLabel: "ՀՎՀՀ",
      addressLabel: "Իրավական/Փաստացի հասցե",
      companyAddress:
        "Հայաստանի Հանրապետություն, Երևան, Կենտրոն վարչական շրջան, Հյուսիսային պրոսպեկտ 1/1",
      emailLabel: "Էլ. փոստ",
      policyAgreeBefore: "Սեղմելով ",
      policyAgreeAfter: " կոճակը՝ հաստատում եմ, որ ծանոթացել եմ ",
      policyAgreeSep: ", ",
      policyAgreeAnd: " և ",
      policyAgreeEnd: " փաստաթղթերին։",
      visitTitle: "Ե՞րբ կարող եք մոտենալ",
      visitNoSlots: "Այս օրվա համար ազատ ժամանակ չկա",
      visitAt: "Ժամանակ"
    },
    ru: {
      chooseCar: "Выберите автомобиль",
      chooseBrand: "Выберите марку",
      chooseModel: "Выберите модель",
      filterPlaceholder: "Введите для поиска…",
      clear: "Очистить",
      customOption: "Свой вариант",
      customLabel: "Ваш автомобиль",
      youSelected: "Вы выбрали",
      noModels: "Нет моделей",
      chooseType: "Выберите тип",
      sedan: "Седан",
      crossover: "Кроссовер",
      suv: "Внедорожник",
      next: "Далее",
      services: "Услуги",
      tapToAdd: "Нажмите, чтобы добавить в корзину",
      added: "Добавлено",
      cart: "Корзина",
      total: "Итого",
      checkout: "Оформление",
      goPay: "Перейти к оплате",
      pay: "Оплатить",
      phone: "Телефон",
      name: "Имя",
      sendOtp: "Отправить код",
      otp: "Код из SMS",
      login: "Вход",
      orders: "Заказы",
      activeOrders: "Активные заказы",
      historyOrders: "История",
      noOrders: "Нет заказов",
      thankYou: "Спасибо!",
      orderAccepted: "Заказ принят",
      newOrder: "Новый заказ",
      loading: "Загрузка…",
      emptyCart: "Корзина пуста",
      statusActive: "Активный",
      statusDone: "Выполнен",
      statusCancelled: "Отменён",
      menuErr: "Меню",
      back: "Назад",
      changePhone: "Изменить номер",
      resendOtp: "Отправить код повторно",
      resendIn: "Повторно через {n} сек",
      profileTitle: "Личные данные",
      account: "Аккаунт",
      langHy: "Հայերեն",
      langRu: "Русский",
      langEn: "English",
      logout: "Выход",
      navTerms: "Пользовательское соглашение",
      navCancellation: "Политика отмены",
      navPrivacy: "Политика конфиденциальности",
      acceptedCards: "Принимаем к оплате",
      contactsTitle: "Контакты",
      companyName: "ООО «Смарт Паркинг» (Smart Parking LLC)",
      tinLabel: "ИНН (ՀՎՀՀ)",
      addressLabel: "Юридический/Фактический адрес",
      companyAddress:
        "Республика Армения, г. Ереван, р-н Кентрон, Северный проспект, 1/1",
      emailLabel: "Email",
      policyAgreeBefore: "Нажимая кнопку «",
      policyAgreeAfter: "», подтверждаю, что ознакомился с ",
      policyAgreeSep: ", ",
      policyAgreeAnd: " и ",
      policyAgreeEnd: ".",
      visitTitle: "Когда можете подъехать?",
      visitNoSlots: "На этот день нет свободного времени",
      visitAt: "Приезд"
    },
    en: {
      chooseCar: "Choose your car",
      chooseBrand: "Choose brand",
      chooseModel: "Choose model",
      filterPlaceholder: "Type to search…",
      clear: "Clear",
      customOption: "Custom",
      customLabel: "Your car",
      youSelected: "You selected",
      noModels: "No models",
      chooseType: "Choose type",
      sedan: "Sedan",
      crossover: "Crossover",
      suv: "SUV",
      next: "Next",
      services: "Services",
      tapToAdd: "Tap to add to cart",
      added: "Added",
      cart: "Cart",
      total: "Total",
      checkout: "Checkout",
      goPay: "Go to payment",
      pay: "Pay",
      phone: "Phone",
      name: "Name",
      sendOtp: "Send code",
      otp: "SMS code",
      login: "Sign in",
      orders: "Orders",
      activeOrders: "Active orders",
      historyOrders: "History",
      noOrders: "No orders",
      thankYou: "Thank you!",
      orderAccepted: "Order accepted",
      newOrder: "New order",
      loading: "Loading…",
      emptyCart: "Cart is empty",
      statusActive: "Active",
      statusDone: "Completed",
      statusCancelled: "Cancelled",
      menuErr: "Menu",
      back: "Back",
      changePhone: "Change number",
      resendOtp: "Resend code",
      resendIn: "Resend in {n}s",
      profileTitle: "Personal details",
      account: "Account",
      langHy: "Հայերեն",
      langRu: "Русский",
      langEn: "English",
      logout: "Log out",
      navTerms: "Terms and conditions",
      navCancellation: "Cancellation policy",
      navPrivacy: "Privacy policy",
      acceptedCards: "Cards accepted",
      contactsTitle: "Contacts",
      companyName: "Smart Parking LLC (Սմարտ Պարկինգ ՍՊԸ)",
      tinLabel: "TIN",
      addressLabel: "Legal / actual address",
      companyAddress:
        "Republic of Armenia, Yerevan, Kentron district, Northern Avenue 1/1",
      emailLabel: "Email",
      policyAgreeBefore: 'By clicking the "',
      policyAgreeAfter: '" button, I confirm that I have read the ',
      policyAgreeSep: ", ",
      policyAgreeAnd: ", and ",
      policyAgreeEnd: ".",
      visitTitle: "When can you arrive?",
      visitNoSlots: "No available times for this day",
      visitAt: "Visit"
    }
  };

  var LEGAL = {
    terms: {
      hy: {
        title: "Օգտագործման պայմաններ",
        sections: [
          {
            title: "1. Ընդհանուր դրույթներ",
            paragraphs: [
              "Սույն պայմանները կարգավորում են hyusisayin-carwash.am կայքի (այսուհետ՝ Կայք) օգտագործումը և «Սմարտ Պարկինգ» ՍՊԸ-ի (Smart Parking LLC, ՀՎՀՀ 02853428) կողմից ավտոլվացման և դետեյլինգի ծառայությունների առցանց պատվիրումն ու վճարումը։",
              "Կայքից օգտվելով և պատվեր հաստատելով՝ օգտատերը հաստատում է, որ ծանոթացել է սույն պայմաններին, չեղարկման քաղաքականությանը և գաղտնիության քաղաքականությանը։"
            ]
          },
          {
            title: "2. Ծառայություններ և գներ",
            paragraphs: [
              "Կայքում առաջարկվում են ավտոլվացման և դետեյլինգի ծառայություններ՝ ըստ ընտրված ավտոմեքենայի տեսակի և պատվերի պահին ցուցադրված ցանկի։",
              "Գները նշված են հայկական դրամով (AMD) և համընկնում են պատվերի ձևակերպման (checkout) էջում ցուցադրված գներին։ Պատվերի գումարը ֆիքսվում է վճարման հաստատման պահին։"
            ]
          },
          {
            title: "3. Պատվեր և այց",
            paragraphs: [
              "Օգտատերը ընտրում է ավտոմեքենան, ծառայությունները և այցի ամսաթիվը/ժամը, անցնում է նույնականացում հեռախոսահամարով և վճարում առցանց։",
              "Օգտատերը պարտավորվում է տրամադրել ճշգրիտ անուն և հեռախոսահամար և ներկայանալ ամրագրված ժամին։ Չեղարկման և չներկայանալու կանոնները նկարագրված են չեղարկման քաղաքականությունում։"
            ]
          },
          {
            title: "4. Վճարում",
            paragraphs: [
              "Վճարումը կատարվում է առցանց՝ հայկական դրամով (AMD) ArCa, Visa, Mastercard և MIR (МИР) քարտերով՝ լիազորված VPOS վճարային դարպասի միջոցով։",
              "Ծառայությունը համարվում է վճարված գումարի հաջող գանձումից և վճարային համակարգի հաստատումից հետո։",
              "Քարտի տվյալները մուտքագրվում են վճարային համակարգի պաշտպանված էջում։ «Սմարտ Պարկինգ» ՍՊԸ-ն չի հավաքում, չի մշակում և չի պահպանում քարտի համարը, գործողության ժամկետը և CVV/CVC կոդը։"
            ]
          },
          {
            title: "5. Անվտանգություն",
            paragraphs: [
              "Կայքը հասանելի է HTTPS արձանագրությամբ։ Տվյալների փոխանցումը կատարվում է TLS/SSL գաղտնագրմամբ։"
            ]
          },
          {
            title: "6. Կիրառելի իրավունք",
            paragraphs: [
              "Սույն պայմանները կարգավորվում են Հայաստանի Հանրապետության օրենսդրությամբ։ Վեճերը լուծվում են բանակցությամբ, իսկ չհամաձայնեցման դեպքում՝ ՀՀ իրավասու դատարաններում։"
            ]
          }
        ]
      },
      ru: {
        title: "Пользовательское соглашение",
        sections: [
          {
            title: "1. Общие положения",
            paragraphs: [
              "Настоящие условия регулируют использование сайта hyusisayin-carwash.am (далее — Сайт) и онлайн-заказ и оплату услуг автомойки и детейлинга, оказываемых ООО «Смарт Паркинг» (Smart Parking LLC, ИНН 02853428).",
              "Используя Сайт и подтверждая заказ, пользователь подтверждает, что ознакомился с настоящими условиями, политикой отмены и политикой конфиденциальности."
            ]
          },
          {
            title: "2. Услуги и цены",
            paragraphs: [
              "На Сайте предлагаются услуги автомойки и детейлинга в соответствии с выбранным типом автомобиля и меню, отображаемым на момент заказа.",
              "Цены указаны в армянских драмах (AMD) и совпадают с ценами на странице оформления заказа (checkout). Сумма заказа фиксируется в момент подтверждения оплаты."
            ]
          },
          {
            title: "3. Заказ и визит",
            paragraphs: [
              "Пользователь выбирает автомобиль, услуги и дату/время визита, проходит идентификацию по номеру телефона и оплачивает заказ онлайн.",
              "Пользователь обязан указать достоверные имя и телефон и прибыть в забронированное время. Правила отмены и неявки описаны в политике отмены."
            ]
          },
          {
            title: "4. Оплата",
            paragraphs: [
              "Оплата выполняется онлайн в армянских драмах (AMD) картами ArCa, Visa, Mastercard и MIR (МИР) через уполномоченный платёжный шлюз VPOS.",
              "Услуга считается оплаченной после успешного списания средств и подтверждения платёжной системы.",
              "Данные карты вводятся на защищённой странице платёжной системы. ООО «Смарт Паркинг» не собирает, не обрабатывает и не хранит номер карты, срок действия и код CVV/CVC."
            ]
          },
          {
            title: "5. Безопасность",
            paragraphs: [
              "Сайт доступен по протоколу HTTPS. Передача данных защищена шифрованием TLS/SSL."
            ]
          },
          {
            title: "6. Применимое право",
            paragraphs: [
              "Настоящие условия регулируются законодательством Республики Армения. Споры решаются путём переговоров, а при недостижении согласия — в компетентных судах РА."
            ]
          }
        ]
      },
      en: {
        title: "Terms and conditions",
        sections: [
          {
            title: "1. General",
            paragraphs: [
              "These terms govern the use of hyusisayin-carwash.am (the “Site”) and the online booking and payment of car wash and detailing services provided by Smart Parking LLC (TIN 02853428).",
              "By using the Site and confirming an order, the user confirms that they have read these terms, the cancellation policy, and the privacy policy."
            ]
          },
          {
            title: "2. Services and prices",
            paragraphs: [
              "The Site offers car wash and detailing services according to the selected vehicle type and the menu shown at the time of the order.",
              "Prices are shown in Armenian drams (AMD) and match the prices on the checkout page. The order amount is fixed when payment is confirmed."
            ]
          },
          {
            title: "3. Order and visit",
            paragraphs: [
              "The user selects a vehicle, services and a visit date/time, verifies a phone number, and pays online.",
              "The user must provide an accurate name and phone number and arrive at the booked time. Cancellation and no-show rules are set out in the cancellation policy."
            ]
          },
          {
            title: "4. Payment",
            paragraphs: [
              "Payment is made online in Armenian drams (AMD) with ArCa, Visa, Mastercard and MIR (МИР) cards via an authorised VPOS payment gateway.",
              "A service is considered paid after funds are successfully charged and the payment system confirms the transaction.",
              "Card details are entered on the payment system’s secure page. Smart Parking LLC does not collect, process, or store the card number, expiry date, or CVV/CVC code."
            ]
          },
          {
            title: "5. Security",
            paragraphs: [
              "The Site is available over HTTPS. Data is transmitted using TLS/SSL encryption."
            ]
          },
          {
            title: "6. Governing law",
            paragraphs: [
              "These terms are governed by the law of the Republic of Armenia. Disputes are resolved by negotiation or, failing that, by the competent courts of the Republic of Armenia."
            ]
          }
        ]
      }
    },
    cancellation: {
      hy: {
        title: "Չեղարկման քաղաքականություն",
        sections: [
          {
            title: "1. Ինչպես չեղարկել",
            paragraphs: [
              "Պատվերը չեղարկելու համար օգտատերը դիմում է «Սմարտ Պարկինգ» ՍՊԸ-ին կոնտակտներում նշված հեռախոսով կամ էլ. փոստով՝ նշելով պատվերի համարը և այցի ամսաթիվը/ժամը։",
              "Չեղարկման պահ է համարվում այն պահը, երբ հարցումն ստացվել է ընկերության կողմից աշխատանքային ժամերին։ Աշխատանքային ժամերից դուրս ստացված հարցումը համարվում է ստացված հաջորդ աշխատանքային օրվա սկզբին։"
            ]
          },
          {
            title: "2. Ժամկետներ և գումարի վերադարձ",
            list: [
              "Եթե չեղարկման հարցումը ստացվել է ամրագրված այցից առնվազն 2 ժամ առաջ՝ վերադարձվում է վճարված գումարի 100%-ը։",
              "Եթե չեղարկման հարցումը ստացվել է ամրագրված այցից պակաս քան 2 ժամ առաջ՝ վճարված գումարը չի վերադարձվում։",
              "Չներկայանալու դեպքում (հաճախորդը չի գալիս ամրագրված ժամին և չի չեղարկել առնվազն 2 ժամ առաջ) վճարված գումարը չի վերադարձվում։",
              "Ծառայությունը սկսվելուց կամ ավարտվելուց հետո վճարված գումարը չի վերադարձվում։",
              "Եթե ծառայությունը չեղարկում կամ չի կարող մատուցել «Սմարտ Պարկինգ» ՍՊԸ-ն՝ վերադարձվում է վճարված գումարի 100%-ը։"
            ]
          },
          {
            title: "3. Վերադարձի կարգ",
            paragraphs: [
              "Հաստատված վերադարձը կատարվում է միայն այն բանկային քարտին, որով կատարվել է վճարումը։ Առցանց վճարման դեպքում կանխիկ վերադարձ չի կատարվում։",
              "Գումարը քարտին մուտքագրվում է հաստատումից հետո 3-ից 14 աշխատանքային օրվա ընթացքում՝ կախված քարտը թողարկող բանկից։"
            ]
          }
        ]
      },
      ru: {
        title: "Политика отмены",
        sections: [
          {
            title: "1. Как отменить заказ",
            paragraphs: [
              "Чтобы отменить заказ, пользователь обращается в ООО «Смарт Паркинг» по телефону или email, указанным в контактах, и сообщает номер заказа и дату/время визита.",
              "Моментом отмены считается момент получения обращения компанией в рабочие часы. Обращение, полученное вне рабочих часов, считается полученным в начале следующего рабочего дня."
            ]
          },
          {
            title: "2. Сроки и возврат денег",
            list: [
              "Если запрос на отмену получен не менее чем за 2 часа до забронированного времени визита — возвращается 100% оплаченной суммы.",
              "Если запрос на отмену получен менее чем за 2 часа до забронированного времени визита — оплаченная сумма не возвращается.",
              "При неявке (клиент не прибыл в забронированное время и не отменил заказ минимум за 2 часа) оплаченная сумма не возвращается.",
              "После начала или завершения услуги оплаченная сумма не возвращается.",
              "Если услугу отменяет или не может оказать ООО «Смарт Паркинг» — возвращается 100% оплаченной суммы."
            ]
          },
          {
            title: "3. Порядок возврата",
            paragraphs: [
              "Одобренный возврат зачисляется только на ту банковскую карту, с которой была сделана оплата. Наличный возврат при онлайн-оплате не производится.",
              "Зачисление на карту занимает от 3 до 14 рабочих дней после одобрения и зависит от банка-эмитента."
            ]
          }
        ]
      },
      en: {
        title: "Cancellation policy",
        sections: [
          {
            title: "1. How to cancel",
            paragraphs: [
              "To cancel an order, the user contacts Smart Parking LLC by the phone or email listed in Contacts and provides the order number and visit date/time.",
              "The cancellation time is the moment the company receives the request during business hours. A request received outside business hours is treated as received at the start of the next business day."
            ]
          },
          {
            title: "2. Deadlines and refunds",
            list: [
              "If the cancellation request is received at least 2 hours before the booked visit time, 100% of the paid amount is refunded.",
              "If the cancellation request is received less than 2 hours before the booked visit time, the paid amount is not refunded.",
              "No-show (the customer does not arrive at the booked time and did not cancel at least 2 hours before): the paid amount is not refunded.",
              "After the service has started or been completed, the paid amount is not refunded.",
              "If Smart Parking LLC cancels or cannot provide the service, 100% of the paid amount is refunded."
            ]
          },
          {
            title: "3. Refund procedure",
            paragraphs: [
              "An approved refund is returned only to the bank card used for the original payment. Cash refunds are not provided for online payments.",
              "The amount is credited to the card within 3 to 14 business days after approval, depending on the issuing bank."
            ]
          }
        ]
      }
    },
    privacy: {
      hy: {
        title: "Գաղտնիության քաղաքականություն",
        sections: [
          {
            title: "1. Տվյալների վերահսկող",
            paragraphs: [
              "Անձնական տվյալների վերահսկողը «Սմարտ Պարկինգ» ՍՊԸ-ն է (Smart Parking LLC, ՀՎՀՀ 02853428), հասցե՝ ՀՀ, Երևան, Կենտրոն, Հյուսիսային պրոսպեկտ 1/1։ Կայք՝ hyusisayin-carwash.am։"
            ]
          },
          {
            title: "2. Ինչ տվյալներ են մշակվում",
            list: [
              "Անուն և հեռախոսահամար (գրանցում, OTP, կապ)։",
              "Ավտոմեքենայի տվյալներ՝ մակնիշ, մոդել, տեսակ կամ օգտատիրոջ նկարագրություն։",
              "Պատվերի տվյալներ՝ ծառայություններ, գումար, այցի ամսաթիվ/ժամ, կարգավիճակ։",
              "Վճարման արդյունք (հաջող/մերժված) առանց քարտի համարի, ժամկետի և CVV/CVC-ի։",
              "Տեխնիկական տվյալներ՝ լեզու, սեսիայի նշան localStorage-ում, անհրաժեշտության դեպքում IP և user-agent՝ անվտանգության համար։"
            ]
          },
          {
            title: "3. Ինչու են մշակվում",
            list: [
              "Պատվերի կատարում և այցի ամրագրում (պայմանագրի կատարում)։",
              "Հեռախոսով նույնականացում (OTP)։",
              "Առցանց վճարման հաստատում վճարային դարպասի միջոցով։",
              "Հաճախորդների սպասարկում և ծանուցումներ։",
              "Հաշվապահական և օրենսդրական պարտավորություններ։"
            ]
          },
          {
            title: "4. Պահպանում և փոխանցում",
            paragraphs: [
              "Տվյալները պահվում են ընկերության համակարգերում Հայաստանի Հանրապետությունում։ Հաշվի և պատվերների տվյալները պահվում են ծառայության ընթացքում, իսկ հաշվապահական փաստաթղթերի համար՝ մինչև 5 տարի վերջին պատվերից հետո, եթե օրենքը այլ բան չի պահանջում։",
              "Ստացողներ՝ վճարային դարպաս (միայն վճարումը կատարելու համար) և SMS/OTP մատակարար (հեռախոսահամար՝ կոդ ուղարկելու համար)։ Քարտի գաղտնի տվյալները ընկերությանը չեն փոխանցվում և չեն պահվում։"
            ]
          },
          {
            title: "5. Օգտատիրոջ իրավունքներ",
            paragraphs: [
              "Օգտատերն իրավունք ունի ծանոթանալ իր տվյալներին, ուղղել դրանք, պահանջել ջնջում (բացառությամբ օրենքով պահպանման դեպքերի), սահմանափակել մշակումը և հետ կանչել համաձայնությունը։",
              "Հարցումները ուղարկվում են info@hyusisayin-carwash.am կամ +374 95 055838 հեռախոսով։ Պատասխանը տրվում է մինչև 30 օրում։"
            ]
          },
          {
            title: "6. Անվտանգություն",
            paragraphs: [
              "Կայքը աշխատում է HTTPS/TLS-ով։ «Սմարտ Պարկինգ» ՍՊԸ-ն չի պահպանում բանկային քարտերի համարը, ժամկետը և CVV/CVC կոդը։"
            ]
          }
        ]
      },
      ru: {
        title: "Политика конфиденциальности",
        sections: [
          {
            title: "1. Оператор данных",
            paragraphs: [
              "Оператор персональных данных — ООО «Смарт Паркинг» (Smart Parking LLC, ИНН 02853428), адрес: РА, г. Ереван, Кентрон, Северный проспект 1/1. Сайт: hyusisayin-carwash.am."
            ]
          },
          {
            title: "2. Какие данные обрабатываются",
            list: [
              "Имя и номер телефона (регистрация, OTP, связь).",
              "Данные автомобиля: марка, модель, тип или описание, указанное пользователем.",
              "Данные заказа: услуги, сумма, дата/время визита, статус.",
              "Результат оплаты (успех/отказ) без номера карты, срока действия и CVV/CVC.",
              "Технические данные: язык, признак сессии в localStorage, при необходимости IP и user-agent для безопасности."
            ]
          },
          {
            title: "3. Для чего обрабатываются",
            list: [
              "Исполнение заказа и запись на визит (исполнение договора).",
              "Идентификация по телефону (OTP).",
              "Подтверждение онлайн-оплаты через платёжный шлюз.",
              "Поддержка клиентов и уведомления.",
              "Бухгалтерские и законные обязанности."
            ]
          },
          {
            title: "4. Хранение и передача",
            paragraphs: [
              "Данные хранятся в системах компании в Республике Армения. Данные аккаунта и заказов хранятся на время оказания услуг, а для бухгалтерских документов — до 5 лет после последнего заказа, если закон не требует иного.",
              "Получатели: платёжный шлюз (только для проведения оплаты) и поставщик SMS/OTP (номер телефона для отправки кода). Секретные данные карты компании не передаются и не хранятся."
            ]
          },
          {
            title: "5. Права пользователя",
            paragraphs: [
              "Пользователь вправе получить доступ к своим данным, исправить их, требовать удаления (кроме случаев обязательного хранения), ограничить обработку и отозвать согласие.",
              "Запросы направляются на info@hyusisayin-carwash.am или по телефону +374 95 055838. Ответ предоставляется в срок до 30 дней."
            ]
          },
          {
            title: "6. Безопасность",
            paragraphs: [
              "Сайт работает по HTTPS/TLS. ООО «Смарт Паркинг» не хранит номер банковской карты, срок действия и код CVV/CVC."
            ]
          }
        ]
      },
      en: {
        title: "Privacy policy",
        sections: [
          {
            title: "1. Data controller",
            paragraphs: [
              "The personal data controller is Smart Parking LLC (TIN 02853428), address: Republic of Armenia, Yerevan, Kentron, Northern Avenue 1/1. Website: hyusisayin-carwash.am."
            ]
          },
          {
            title: "2. What data is processed",
            list: [
              "Name and phone number (registration, OTP, contact).",
              "Vehicle data: brand, model, type, or a description entered by the user.",
              "Order data: services, amount, visit date/time, status.",
              "Payment result (success/failure) without card number, expiry date, or CVV/CVC.",
              "Technical data: language, a session token in localStorage, and if needed IP and user-agent for security."
            ]
          },
          {
            title: "3. Why it is processed",
            list: [
              "To fulfil the booking and provide the visit (performance of a contract).",
              "Phone verification (OTP).",
              "To confirm online payment via the payment gateway.",
              "Customer support and notices.",
              "Accounting and legal obligations."
            ]
          },
          {
            title: "4. Storage and sharing",
            paragraphs: [
              "Data is stored in the company’s systems in the Republic of Armenia. Account and order data is kept while services are provided and, for accounting records, for up to 5 years after the last order unless the law requires longer.",
              "Recipients: the payment gateway (only to process payment) and the SMS/OTP provider (phone number to send the code). Card secrets are not transferred to or stored by the company."
            ]
          },
          {
            title: "5. User rights",
            paragraphs: [
              "The user may access their data, correct it, request erasure (except where retention is required by law), restrict processing, and withdraw consent.",
              "Requests are sent to info@hyusisayin-carwash.am or +374 95 055838. A response is provided within 30 days."
            ]
          },
          {
            title: "6. Security",
            paragraphs: [
              "The Site uses HTTPS/TLS. Smart Parking LLC does not store bank card numbers, expiry dates, or CVV/CVC codes."
            ]
          }
        ]
      }
    }
  };

  var OTP_RESEND_SEC = 120;
  var OTP_STALE_SEC = 600;
  var VISIT_DAYS_AHEAD = 3;
  var VISIT_SLOT_MINUTES = 30;
  /** true — слоты с бэкенда (get-visit-slots); false — локальная заглушка */
  var VISIT_SLOTS_FROM_BACKEND = true;

  var CAR_TYPES = [1, 2, 3];

  var state = {
    view: V.HOME,
    locale: loadLocale(),
    catalogLoading: true,
    menuLoading: true,
    catalogError: null,
    menuError: null,
    cars: [],
    models: [],
    modelsBrandId: null,
    modelsLoading: false,
    modelsError: null,
    modelsCache: {},
    carBrandId: null,
    carModelId: null,
    brandFilter: "",
    modelFilter: "",
    customMode: false,
    customText: "",
    manualType: null,
    part2: [],
    dishes: [],
    cart: [],
    cartBump: false,
    customer: loadSession(),
    authStep: "phone",
    pendingToken: "",
    otpSentAt: 0,
    orders: { active: [], history: [] },
    lastOrderId: null,
    lastOrderTotal: 0,
    profileReturnView: V.HOME,
    policyReturnView: V.HOME,
    policyAgreed: false,
    visitDateOffset: 0,
    visitTime: null,
    visitSlots: [],
    visitSlotsLoading: false,
    visitSlotsError: null,
    visitSlotsDate: null
  };

  var els = {};
  var otpTickerId = null;
  var modelsFetchSeq = 0;

  function otpResendSecondsLeft() {
    if (!state.otpSentAt) return OTP_RESEND_SEC;
    var left = OTP_RESEND_SEC - Math.floor((Date.now() - state.otpSentAt) / 1000);
    return left > 0 ? left : 0;
  }

  function canResendOtp() {
    return !!state.pendingToken && otpResendSecondsLeft() === 0;
  }

  function stopOtpTicker() {
    if (otpTickerId) {
      clearInterval(otpTickerId);
      otpTickerId = null;
    }
  }

  function updateResendBtn() {
    var btn = document.getElementById("btn-resend-otp");
    if (!btn) return;
    var left = otpResendSecondsLeft();
    if (left > 0) {
      btn.disabled = true;
      btn.textContent = t("resendIn").replace("{n}", String(left));
    } else {
      btn.disabled = false;
      btn.textContent = t("resendOtp");
    }
  }

  function startOtpTicker() {
    stopOtpTicker();
    var authView = state.view === V.CHECKOUT || state.view === V.PROFILE;
    if (!authView || state.authStep !== "otp" || state.customer.verified) {
      return;
    }
    updateResendBtn();
    otpTickerId = setInterval(function () {
      if (
        (state.view !== V.CHECKOUT && state.view !== V.PROFILE) ||
        state.authStep !== "otp"
      ) {
        stopOtpTicker();
        return;
      }
      updateResendBtn();
    }, 1000);
  }

  function resetAuthPending() {
    state.authStep = "phone";
    state.pendingToken = "";
    state.otpSentAt = 0;
    stopOtpTicker();
  }

  function editPhone() {
    resetAuthPending();
    render();
  }

  function normalizeCheckoutAuth() {
    if (state.customer.verified) return;
    if (state.authStep !== "otp") return;
    if (!state.pendingToken || !state.otpSentAt) {
      resetAuthPending();
      return;
    }
    if (Date.now() - state.otpSentAt > OTP_STALE_SEC * 1000) {
      resetAuthPending();
      toast(t("resendOtp"));
    }
  }

  function t(key) {
    return (I18N[state.locale] && I18N[state.locale][key]) || I18N.hy[key] || key;
  }

  function getSiteBase() {
    if (typeof window.__SITE_BASE__ === "string" && window.__SITE_BASE__) {
      var b = window.__SITE_BASE__;
      return b.charAt(b.length - 1) === "/" ? b : b + "/";
    }
    var path = window.location.pathname || "/";
    var m = path.match(/^(.*\/costumer\.order)\/?/i);
    if (m) return m[1] + "/";
    return "/";
  }

  function pathSegments() {
    var base = getSiteBase().replace(/\/$/, "");
    var path = window.location.pathname || "/";
    if (base && path.indexOf(base) === 0) {
      path = path.slice(base.length) || "/";
    }
    return path.split("/").filter(Boolean);
  }

  function localeFromPath() {
    var parts = pathSegments();
    if (parts.length && LANGS.indexOf(parts[0]) >= 0) return parts[0];
    return null;
  }

  function routeFromPath() {
    var parts = pathSegments();
    var locale = null;
    var page = "";
    if (parts.length && LANGS.indexOf(parts[0]) >= 0) {
      locale = parts[0];
      page = parts[1] || "";
    } else if (parts.length && LEGAL_PATHS[parts[0]]) {
      page = parts[0];
    }
    var view = V.HOME;
    if (LEGAL_PATHS[page]) {
      view = LEGAL_PATHS[page];
    }
    return { locale: locale, view: view };
  }

  function isLegalView(view) {
    return view === V.TERMS || view === V.CANCELLATION || view === V.PRIVACY;
  }

  function appUrl(locale, view) {
    var base = getSiteBase().replace(/\/$/, "");
    var path = (base ? base : "") + "/" + locale;
    if (isLegalView(view)) {
      path += "/" + view;
    }
    return path;
  }

  function syncAppUrl(usePush) {
    var desired = appUrl(state.locale, state.view);
    var current = window.location.pathname.replace(/\/$/, "");
    var desiredNorm = desired.replace(/\/$/, "");
    if (current !== desiredNorm) {
      var full = desired + window.location.search + window.location.hash;
      if (usePush) {
        history.pushState(
          { locale: state.locale, view: state.view },
          "",
          full
        );
      } else {
        history.replaceState(
          { locale: state.locale, view: state.view },
          "",
          full
        );
      }
    }
    document.documentElement.lang = state.locale;
  }

  function ensureLocaleInUrl() {
    var route = routeFromPath();
    if (route.locale) {
      state.locale = route.locale;
      document.documentElement.lang = state.locale;
      if (isLegalView(route.view)) {
        state.policyReturnView = V.HOME;
        state.view = route.view;
      }
      return;
    }
    state.locale = loadLocale();
    if (isLegalView(route.view)) {
      state.policyReturnView = V.HOME;
      state.view = route.view;
    }
    syncAppUrl(false);
  }

  function loadLocale() {
    var fromPath = localeFromPath();
    if (fromPath) return fromPath;
    var q = getQueryParam("lang");
    if (q && LANGS.indexOf(q) >= 0) return q;
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        var o = JSON.parse(raw);
        if (o.locale && LANGS.indexOf(o.locale) >= 0) return o.locale;
      }
    } catch (e) {
      // ignore
    }
    return "hy";
  }

  function loadSession() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return emptyCustomer();
      var o = JSON.parse(raw);
      return {
        token: o.token || "",
        f_id: o.f_id || 0,
        phone: o.phone || "",
        name: o.name || "",
        verified: !!o.token
      };
    } catch (e) {
      return emptyCustomer();
    }
  }

  function emptyCustomer() {
    return { token: "", f_id: 0, phone: "", name: "", verified: false };
  }

  function saveSession() {
    try {
      localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({
          token: state.customer.token,
          f_id: state.customer.f_id,
          phone: state.customer.phone,
          name: state.customer.name,
          locale: state.locale
        })
      );
    } catch (e) {
      // ignore
    }
  }

  function getQueryParam(name) {
    var q = window.location.search || "";
    var s = q.replace(/^\?/, "");
    if (!s) return null;
    var parts = s.split("&");
    for (var i = 0; i < parts.length; i++) {
      var kv = parts[i].split("=");
      var k = decodeURIComponent((kv[0] || "").replace(/\+/g, " "));
      if (k === name) {
        return decodeURIComponent((kv[1] || "").replace(/\+/g, " "));
      }
    }
    return null;
  }

  function apiPath(action) {
    var customApi = getQueryParam("api");
    if (customApi && action === "get-menu") {
      return customApi;
    }

    var apibase = getQueryParam("apibase");
    if (apibase) {
      apibase = apibase.replace(/\/$/, "");
      return apibase + "/v2/carwash/customer/" + action;
    }

    var scripts = document.getElementsByTagName("script");
    for (var i = scripts.length - 1; i >= 0; i--) {
      var src = scripts[i].getAttribute("src") || "";
      if (src.indexOf("app.js") < 0) continue;
      try {
        var scriptUrl = new URL(src, window.location.href);
        var scriptBase = scriptUrl.pathname.replace(/\/[^/]*$/, "/");
        if (/\/costumer\.order\/$/i.test(scriptBase)) {
          return new URL(
            "../engine/v2/carwash/customer/" + action,
            scriptUrl
          ).pathname;
        }
      } catch (e) {
        // ignore
      }
      break;
    }
    return "/engine/v2/carwash/customer/" + action;
  }

  function menuApiUrls() {
    var urls = [];
    var seen = {};
    function add(u) {
      if (!u || seen[u]) return;
      seen[u] = true;
      urls.push(u);
    }
    add(getQueryParam("api"));
    add(apiPath("get-menu"));
    add(apiPath("get-menu").replace("/customer/get-menu", "/customer-order/get-menu"));
    return urls;
  }

  function fmtMoney(n) {
    var v = Number(n) || 0;
    return String(Math.floor(v)) + "֏";
  }

  function toast(msg) {
    if (!els.toast) return;
    els.toast.textContent = msg;
    els.toast.classList.add("show");
    clearTimeout(toast._t);
    toast._t = setTimeout(function () {
      els.toast.classList.remove("show");
    }, 2200);
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function escapeAttr(s) {
    return escapeHtml(s).replace(/'/g, "&#39;");
  }

  function cartTotal() {
    var s = 0;
    state.cart.forEach(function (c) {
      s += (Number(c.f_price) || 0) * (Number(c.f_qty) || 0);
    });
    return s;
  }

  function cartCount() {
    var n = 0;
    state.cart.forEach(function (c) {
      n += Number(c.f_qty) || 0;
    });
    return n;
  }

  function dishKey(d) {
    return String(d.f_dish || d.f_dish_name || "");
  }

  function groupIdForPart1(part1Id) {
    var ids = {};
    state.part2.forEach(function (p2) {
      if (String(p2.f_part) === String(part1Id)) {
        ids[String(p2.f_id)] = true;
      }
    });
    return ids;
  }

  function carTypeName(typeId) {
    var id = parseInt(typeId, 10);
    if (id === 1) return t("sedan");
    if (id === 2) return t("crossover");
    if (id === 3) return t("suv");
    return "";
  }

  function getSelectedBrand() {
    if (!state.carBrandId) return null;
    return state.cars.find(function (c) {
      return String(c.f_id) === String(state.carBrandId);
    });
  }

  function getSelectedModel() {
    if (!state.carModelId) return null;
    return state.models.find(function (m) {
      return String(m.f_id) === String(state.carModelId);
    });
  }

  function modelsForBrand(brandId) {
    if (!brandId) return [];
    if (String(state.modelsBrandId) === String(brandId)) return state.models;
    var cached = state.modelsCache[String(brandId)];
    return cached || [];
  }

  function getEffectiveCarType() {
    if (state.customMode) return state.manualType;
    var model = getSelectedModel();
    return model ? parseInt(model.f_type, 10) : null;
  }

  function canProceedHome() {
    if (!state.policyAgreed) return false;
    if (state.customMode) {
      return (
        state.customText.trim().length >= 2 &&
        CAR_TYPES.indexOf(state.manualType) >= 0
      );
    }
    return !!(state.carBrandId && state.carModelId);
  }

  function visitLocaleTag() {
    if (state.locale === "hy") return "hy-AM";
    if (state.locale === "ru") return "ru-RU";
    return "en-US";
  }

  function visitYmdForOffset(offset) {
    var d = new Date();
    d.setHours(0, 0, 0, 0);
    d.setDate(d.getDate() + (offset || 0));
    var y = d.getFullYear();
    var m = d.getMonth() + 1;
    var day = d.getDate();
    return (
      y +
      "-" +
      (m < 10 ? "0" : "") +
      m +
      "-" +
      (day < 10 ? "0" : "") +
      day
    );
  }

  function formatVisitDateLabel(offset) {
    var d = new Date();
    d.setHours(12, 0, 0, 0);
    d.setDate(d.getDate() + (offset || 0));
    try {
      return new Intl.DateTimeFormat(visitLocaleTag(), {
        weekday: "short",
        day: "numeric",
        month: "short"
      }).format(d);
    } catch (e) {
      return visitYmdForOffset(offset);
    }
  }

  function slotToMinutes(slot) {
    var p = String(slot || "").split(":");
    return (parseInt(p[0], 10) || 0) * 60 + (parseInt(p[1], 10) || 0);
  }

  function minutesToSlot(mins) {
    var h = Math.floor(mins / 60);
    var m = mins % 60;
    return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
  }

  function ceilToNextSlotMinutes(d) {
    var mins = d.getHours() * 60 + d.getMinutes();
    var rem = mins % VISIT_SLOT_MINUTES;
    if (rem > 0) mins += VISIT_SLOT_MINUTES - rem;
    else if (d.getSeconds() > 0 || d.getMilliseconds() > 0) {
      mins += VISIT_SLOT_MINUTES;
    }
    if (mins >= 24 * 60) return 24 * 60;
    return mins;
  }

  function buildLocalVisitSlots(ymd) {
    var slots = [];
    var h;
    var m;
    for (h = 0; h < 24; h++) {
      for (m = 0; m < 60; m += VISIT_SLOT_MINUTES) {
        slots.push(minutesToSlot(h * 60 + m));
      }
    }
    if (ymd === visitYmdForOffset(0)) {
      var cutoff = ceilToNextSlotMinutes(new Date());
      slots = slots.filter(function (s) {
        return slotToMinutes(s) >= cutoff;
      });
    }
    return slots;
  }

  function fetchVisitSlots(ymd) {
    if (VISIT_SLOTS_FROM_BACKEND) {
      return apiPost("get-visit-slots", {
        f_date: ymd,
        locale: state.locale
      }).then(function (json) {
        return json.data || json;
      });
    }
    return Promise.resolve({
      slots: buildLocalVisitSlots(ymd),
      f_date: ymd
    });
  }

  function ensureVisitSelection() {
    if (!state.visitSlots.length) {
      state.visitTime = null;
      return;
    }
    if (
      !state.visitTime ||
      state.visitSlots.indexOf(state.visitTime) < 0
    ) {
      state.visitTime = state.visitSlots[0];
    }
  }

  function loadVisitSlotsForCurrentDate() {
    var ymd = visitYmdForOffset(state.visitDateOffset);
    if (state.visitSlotsDate === ymd && state.visitSlots.length) {
      ensureVisitSelection();
      return Promise.resolve();
    }
    state.visitSlotsLoading = true;
    state.visitSlotsError = null;
    return fetchVisitSlots(ymd)
      .then(function (data) {
        state.visitSlots = data.slots || [];
        state.visitSlotsDate = ymd;
        ensureVisitSelection();
      })
      .catch(function (err) {
        state.visitSlots = buildLocalVisitSlots(ymd);
        state.visitSlotsDate = ymd;
        state.visitSlotsError = String(err.message || err);
        ensureVisitSelection();
      })
      .finally(function () {
        state.visitSlotsLoading = false;
      });
  }

  function canProceedVisit() {
    return !!(
      state.visitTime && state.visitSlots.indexOf(state.visitTime) >= 0
    );
  }

  function buildVisitPayload() {
    var ymd = visitYmdForOffset(state.visitDateOffset);
    var time = state.visitTime || "00:00";
    return {
      f_date: ymd,
      f_time: time,
      f_datetime: ymd + " " + time + ":00"
    };
  }

  function resetVisitSelection() {
    state.visitDateOffset = 0;
    state.visitTime = null;
    state.visitSlots = [];
    state.visitSlotsDate = null;
    state.visitSlotsLoading = false;
    state.visitSlotsError = null;
  }

  function formatVisitDisplay(visit) {
    if (!visit || typeof visit !== "object") return "";
    var dt = visit.f_datetime || "";
    if (dt.length >= 16) return dt.substring(0, 16).replace("T", " ");
    if (visit.f_date && visit.f_time) {
      return visit.f_date + " " + visit.f_time;
    }
    return "";
  }

  function buildCarPayload() {
    var typeId = getEffectiveCarType();
    if (state.customMode) {
      return {
        custom: true,
        custom_text: state.customText.trim(),
        f_type: typeId,
        type_name: carTypeName(typeId)
      };
    }
    var brand = getSelectedBrand();
    var model = getSelectedModel();
    return {
      custom: false,
      brand: brand ? { f_id: brand.f_id, f_name: brand.f_name } : null,
      model: model
        ? {
            f_id: model.f_id,
            f_name: model.f_name,
            f_type: parseInt(model.f_type, 10)
          }
        : null,
      f_type: typeId,
      type_name: carTypeName(typeId)
    };
  }

  function carMenuTitle() {
    if (state.customMode) return state.customText.trim();
    var brand = getSelectedBrand();
    var model = getSelectedModel();
    if (brand && model) return brand.f_name + " " + model.f_name;
    return t("services");
  }

  function resetCarSelection() {
    state.carBrandId = null;
    state.carModelId = null;
    state.brandFilter = "";
    state.modelFilter = "";
    state.customMode = false;
    state.customText = "";
    state.manualType = null;
    state.models = [];
    state.modelsBrandId = null;
    state.modelsLoading = false;
    state.modelsError = null;
    state.policyAgreed = false;
    resetVisitSelection();
  }

  function filterByName(items, query, key) {
    var q = (query || "").trim().toLowerCase();
    if (!q) return items;
    return items.filter(function (item) {
      return String(item[key] || "")
        .toLowerCase()
        .indexOf(q) >= 0;
    });
  }

  function dishesForCarType() {
    var typeId = getEffectiveCarType();
    if (!typeId) return [];
    var groups = groupIdForPart1(typeId);
    var list = state.dishes.filter(function (d) {
      if (Object.keys(groups).length === 0) return true;
      return !!groups[String(d.f_part)];
    });
    if (list.length === 0 && state.dishes.length > 0) {
      return state.dishes.slice();
    }
    return list;
  }

  function formatPhoneInput(raw) {
    var digits = String(raw || "").replace(/\D/g, "");
    if (digits.indexOf("374") === 0) digits = digits.slice(3);
    digits = digits.slice(0, 8);
    var out = "+374";
    if (digits.length > 0) out += " " + digits.slice(0, 2);
    if (digits.length > 2) out += " " + digits.slice(2, 5);
    if (digits.length > 5) out += " " + digits.slice(5, 8);
    return out.trim();
  }

  function phoneDigits(raw) {
    var d = String(raw || "").replace(/\D/g, "");
    if (d.indexOf("374") === 0) d = d.slice(3);
    return d;
  }

  function customerApiUrls(action) {
    var urls = [];
    var seen = {};
    function add(u) {
      if (!u || seen[u]) return;
      seen[u] = true;
      urls.push(u);
    }
    add(apiPath(action));
    add(apiPath(action).replace("/customer/", "/customer-order/"));
    return urls;
  }

  function parseJsonResponse(res) {
    return res.text().then(function (text) {
      var trimmed = (text || "").trim();
      if (!trimmed) throw new Error("Empty response (HTTP " + res.status + ")");
      if (trimmed.charAt(0) === "<") {
        throw new Error("HTML instead of JSON (HTTP " + res.status + ")");
      }
      try {
        return JSON.parse(trimmed);
      } catch (e) {
        throw new Error(trimmed.slice(0, 160));
      }
    });
  }

  function apiPost(action, body, auth) {
    var urls = action === "get-menu" ? menuApiUrls() : customerApiUrls(action);
    function tryUrl(index) {
      if (index >= urls.length) {
        return Promise.reject(new Error("API failed: " + action));
      }
      return apiPostUrl(urls[index], body, auth).catch(function (err) {
        var msg = String(err.message || err);
        if (index + 1 < urls.length && msg.indexOf("HTML") >= 0) {
          return tryUrl(index + 1);
        }
        err._apiUrl = urls[index];
        throw err;
      });
    }
    return tryUrl(0);
  }

  function apiPostUrl(url, body, auth) {
    var headers = {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Application-Name": "carwash",
      "X-Application-Version": "1.0.2"
    };
    if (auth && state.customer.token) {
      headers.Authorization = "Bearer " + state.customer.token;
    }
    return fetch(url, {
      method: "POST",
      cache: "no-store",
      headers: headers,
      body: JSON.stringify(body || {})
    }).then(function (res) {
      return parseJsonResponse(res).then(function (json) {
        if (json.status !== 1 && json.status !== true) {
          throw new Error((json && json.data) || "Request failed");
        }
        return json;
      });
    });
  }

  function fetchCatalog() {
    state.catalogLoading = true;
    state.catalogError = null;
    return apiPost("get-car-catalog", { locale: state.locale })
      .then(function (json) {
        var data = json.data || {};
        state.cars = data.cars || [];
        state.catalogLoading = false;
        state.catalogError = null;
      })
      .catch(function (err) {
        state.catalogLoading = false;
        state.catalogError = String(err.message || err);
      });
  }

  function fetchModelsForBrand(brandId) {
    if (!brandId) {
      state.models = [];
      state.modelsBrandId = null;
      state.modelsLoading = false;
      state.modelsError = null;
      return Promise.resolve();
    }

    var key = String(brandId);
    if (state.modelsCache[key]) {
      state.models = state.modelsCache[key];
      state.modelsBrandId = brandId;
      state.modelsLoading = false;
      state.modelsError = null;
      return Promise.resolve();
    }

    var seq = ++modelsFetchSeq;
    state.modelsLoading = true;
    state.modelsError = null;
    state.models = [];
    state.modelsBrandId = brandId;

    return apiPost("get-car-catalog", {
      f_car: parseInt(brandId, 10) || brandId,
      locale: state.locale
    })
      .then(function (json) {
        if (seq !== modelsFetchSeq) return;
        var data = json.data || {};
        var models = data.models || [];
        state.modelsCache[key] = models;
        state.models = models;
        state.modelsBrandId = brandId;
        state.modelsLoading = false;
        state.modelsError = null;
      })
      .catch(function (err) {
        if (seq !== modelsFetchSeq) return;
        state.modelsLoading = false;
        state.modelsError = String(err.message || err);
        toast(state.modelsError);
      });
  }

  function selectBrand(brandId, brandName) {
    state.carBrandId = brandId;
    state.carModelId = null;
    state.modelFilter = "";
    if (brandName) state.brandFilter = brandName;
    render();
    var loadPromise = fetchModelsForBrand(brandId);
    if (state.modelsLoading) render();
    loadPromise.then(function () {
      if (state.view !== V.HOME) return;
      if (String(state.carBrandId) !== String(brandId)) return;
      render();
      var modelFilter = document.getElementById("model-filter");
      if (modelFilter && !state.customMode) {
        modelFilter.focus();
      }
    });
  }

  function fetchMenu() {
    state.menuLoading = true;
    state.menuError = null;

    var urls = menuApiUrls();
    var body = { f_menu: DEFAULT_MENU, locale: state.locale };

    function tryUrl(index) {
      if (index >= urls.length) {
        return Promise.reject(new Error("Menu API failed"));
      }
      return apiPostUrl(urls[index], body, false).catch(function (err) {
        var msg = String(err.message || err);
        if (index + 1 < urls.length && msg.indexOf("HTML") >= 0) {
          return tryUrl(index + 1);
        }
        err._apiUrl = urls[index];
        throw err;
      });
    }

    return tryUrl(0)
      .then(function (json) {
        var data = json.data || {};
        state.part2 = data.part2 || [];
        state.dishes = data.dish || [];
        state.menuLoading = false;
        state.menuError = null;
      })
      .catch(function (err) {
        state.menuLoading = false;
        var msg = String(err.message || err);
        if (err._apiUrl) msg += " (" + err._apiUrl + ")";
        state.menuError = msg;
      });
  }

  function fetchOrders() {
    if (!state.customer.verified) return Promise.resolve();
    return apiPost("list-orders", {}, true)
      .then(function (json) {
        state.orders = json.data || { active: [], history: [] };
        render();
      })
      .catch(function (err) {
        toast(String(err.message || err));
      });
  }

  function sendOtp(isResend) {
    var phone = formatPhoneInput(state.customer.phone);
    var name = (state.customer.name || "").trim();
    if (phoneDigits(phone).length !== 8 || name.length < 2) {
      toast(t("phone") + " / " + t("name"));
      return;
    }
    if (isResend && !canResendOtp()) {
      toast(t("resendIn").replace("{n}", String(otpResendSecondsLeft())));
      return;
    }
    apiPost("send-otp", { phone: phone, name: name, locale: state.locale })
      .then(function (json) {
        var data = json.data || {};
        state.pendingToken = data.token || "";
        state.customer.phone = data.phone || phone;
        state.customer.name = name;
        state.authStep = "otp";
        state.otpSentAt = Date.now();
        toast(isResend ? t("resendOtp") : t("sendOtp"));
        render();
        startOtpTicker();
      })
      .catch(function (err) {
        toast(String(err.message || err));
      });
  }

  function resendOtp() {
    sendOtp(true);
  }

  function verifyOtp(code) {
    if (!state.pendingToken) {
      toast(t("sendOtp"));
      editPhone();
      return;
    }
    var digits = String(code || "").replace(/\D/g, "");
    if (digits.length < 4) {
      toast(t("otp"));
      return;
    }
    apiPost("verify-otp", { token: state.pendingToken, code: digits })
      .then(function (json) {
        var data = json.data || {};
        var user = data.user || {};
        state.customer.token = data.token || "";
        state.customer.f_id = user.f_id || 0;
        state.customer.phone = user.f_phone || state.customer.phone;
        state.customer.name = user.f_name || state.customer.name;
        state.customer.verified = !!state.customer.token;
        state.pendingToken = "";
        state.otpSentAt = 0;
        stopOtpTicker();
        state.authStep = "phone";
        saveSession();
        toast(t("login"));
        render();
      })
      .catch(function (err) {
        var msg = String(err.message || err);
        if (err._apiUrl) msg += " (" + err._apiUrl + ")";
        toast(msg);
      });
  }

  function submitOrder() {
    apiPost(
      "submit-order",
      {
        car: buildCarPayload(),
        cart: state.cart,
        total: cartTotal(),
        visit: buildVisitPayload(),
        payment: { method: "stub", paid: true },
        locale: state.locale
      },
      true
    )
      .then(function (json) {
        state.lastOrderId = (json.data && json.data.f_id) || null;
        state.lastOrderTotal = cartTotal();
        state.view = V.SUCCESS;
        state.cart = [];
        render();
      })
      .catch(function (err) {
        toast(String(err.message || err));
      });
  }

  function logout() {
    state.customer = emptyCustomer();
    resetAuthPending();
    saveSession();
    setView(V.HOME);
    toast(t("logout"));
  }

  function openAccount() {
    state.profileReturnView = state.view;
    setView(V.PROFILE);
  }

  function goHome() {
    setView(V.HOME);
  }

  function matchesPickerQuery(name, query) {
    var q = (query || "").trim().toLowerCase();
    if (!q) return false;
    var words = String(name || "")
      .trim()
      .toLowerCase()
      .split(/\s+/);
    for (var i = 0; i < words.length; i++) {
      if (words[i].indexOf(q) === 0) return true;
    }
    return false;
  }

  function applyPickerFilter(inputEl, listEl, hideWhenEmpty) {
    if (!inputEl || !listEl) return;
    var q = (inputEl.value || "").trim();
    var hasQuery = q.length > 0;
    listEl.querySelectorAll(".picker-item").forEach(function (btn) {
      var name = btn.getAttribute("data-name") || "";
      var li = btn.closest("li");
      if (!li) return;
      if (!hasQuery) {
        li.hidden = !!hideWhenEmpty;
      } else {
        li.hidden = !matchesPickerQuery(name, q);
      }
    });
  }

  function updatePickerClear(inputEl, clearBtn) {
    if (!clearBtn) return;
    var hasText = !!(inputEl && (inputEl.value || "").length);
    clearBtn.disabled = !inputEl || inputEl.disabled || !hasText;
  }

  function wirePickerClear(inputEl, clearBtn, listEl, hideWhenEmpty, onClear) {
    if (!inputEl || !clearBtn) return;
    updatePickerClear(inputEl, clearBtn);
    clearBtn.onclick = function () {
      if (clearBtn.disabled) return;
      inputEl.value = "";
      if (onClear) onClear();
      applyPickerFilter(inputEl, listEl, hideWhenEmpty);
      updatePickerClear(inputEl, clearBtn);
      inputEl.focus();
    };
  }

  function wireHomePickers() {
    var brandFilter = document.getElementById("brand-filter");
    var brandList = document.getElementById("brand-list");
    var modelFilter = document.getElementById("model-filter");
    var modelList = document.getElementById("model-list");

    if (brandFilter && brandList) {
      var brandClear = document.getElementById("brand-clear");
      brandFilter.oninput = function () {
        state.brandFilter = brandFilter.value;
        applyPickerFilter(brandFilter, brandList, true);
        updatePickerClear(brandFilter, brandClear);
      };
      wirePickerClear(brandFilter, brandClear, brandList, true, function () {
        state.brandFilter = "";
        state.carBrandId = null;
        state.carModelId = null;
        state.models = [];
        state.modelsBrandId = null;
        state.modelFilter = "";
        render();
      });
      applyPickerFilter(brandFilter, brandList, true);
      updatePickerClear(brandFilter, brandClear);
    }
    if (modelFilter && modelList) {
      var modelClear = document.getElementById("model-clear");
      modelFilter.oninput = function () {
        state.modelFilter = modelFilter.value;
        applyPickerFilter(modelFilter, modelList, false);
        updatePickerClear(modelFilter, modelClear);
      };
      wirePickerClear(modelFilter, modelClear, modelList, false, function () {
        state.modelFilter = "";
      });
      applyPickerFilter(modelFilter, modelList, false);
      updatePickerClear(modelFilter, modelClear);
    }

    els.main.querySelectorAll("#brand-list .picker-item").forEach(function (btn) {
      btn.onclick = function () {
        if (state.customMode) return;
        selectBrand(btn.getAttribute("data-id"), btn.getAttribute("data-name"));
      };
    });

    els.main.querySelectorAll("#model-list .picker-item").forEach(function (btn) {
      btn.onclick = function () {
        if (state.customMode) return;
        state.carModelId = btn.getAttribute("data-id");
        render();
      };
    });

    var customCheck = document.getElementById("custom-mode-check");
    if (customCheck) {
      customCheck.onchange = function () {
        state.customMode = customCheck.checked;
        if (state.customMode) {
          state.carBrandId = null;
          state.carModelId = null;
          state.brandFilter = "";
          state.modelFilter = "";
          state.models = [];
          state.modelsBrandId = null;
          state.modelsLoading = false;
          state.modelsError = null;
        } else {
          state.customText = "";
          state.manualType = null;
        }
        render();
      };
    }

    var customText = document.getElementById("custom-text");
    if (customText) {
      customText.oninput = function () {
        state.customText = customText.value;
        var pos = customText.selectionStart;
        render();
        var again = document.getElementById("custom-text");
        if (again) {
          again.focus();
          try {
            again.setSelectionRange(pos, pos);
          } catch (e) {
            // ignore
          }
        }
      };
    }

    els.main.querySelectorAll(".type-pick-btn").forEach(function (btn) {
      btn.onclick = function () {
        state.manualType = parseInt(btn.getAttribute("data-type"), 10);
        render();
      };
    });
  }

  function setView(v, opts) {
    opts = opts || {};
    if (
      (state.view === V.CHECKOUT &&
        v !== V.CHECKOUT &&
        v !== V.PAYMENT &&
        !isLegalView(v)) ||
      (state.view === V.PROFILE && v !== V.PROFILE && v !== V.ORDERS)
    ) {
      if (!state.customer.verified) {
        resetAuthPending();
      }
    }
    if (v === V.CHECKOUT && !state.customer.verified) {
      normalizeCheckoutAuth();
    }
    if (v !== V.CHECKOUT && v !== V.PROFILE) {
      stopOtpTicker();
    }
    state.view = v;
    syncAppUrl(!!opts.pushUrl);
    if (v === V.ORDERS) {
      fetchOrders().then(render);
    } else if (v === V.VISIT) {
      loadVisitSlotsForCurrentDate().then(render);
    } else {
      render();
    }
    if (
      (v === V.CHECKOUT || v === V.PROFILE) &&
      state.authStep === "otp" &&
      !state.customer.verified
    ) {
      startOtpTicker();
    }
  }

  function bumpCart() {
    state.cartBump = true;
    render();
    setTimeout(function () {
      state.cartBump = false;
      if (els.btnCart) els.btnCart.classList.remove("cart-bump");
    }, 450);
  }

  function formatCartBadge(total) {
    if (total <= 0) return "";
    var n = Math.round(total);
    if (n >= 10000) return Math.round(n / 1000) + "k";
    if (n >= 1000) {
      var k = n / 1000;
      return (k % 1 === 0 ? k.toFixed(0) : k.toFixed(1)) + "k";
    }
    return String(n);
  }

  function setLocaleFromSelect(locale) {
    if (!locale || locale === state.locale || LANGS.indexOf(locale) < 0) return;
    state.locale = locale;
    saveSession();
    syncAppUrl(false);
    render();
    state.modelsCache = {};
    var brandId = state.carBrandId;
    Promise.all([fetchCatalog(), fetchMenu()])
      .then(function () {
        if (brandId) return fetchModelsForBrand(brandId);
      })
      .then(function () {
        render();
      })
      .catch(function () {
        render();
      });
  }

  function renderAuthFormHtml() {
    if (state.customer.verified) return "";
    if (state.authStep === "phone") {
      return (
        '<div class="auth-form">' +
        '<label>' +
        escapeHtml(t("phone")) +
        '</label><input type="tel" id="inp-phone" inputmode="tel" value="' +
        escapeAttr(formatPhoneInput(state.customer.phone || "+374")) +
        '">' +
        '<label>' +
        escapeHtml(t("name")) +
        '</label><input type="text" id="inp-name" value="' +
        escapeAttr(state.customer.name) +
        '">' +
        '<button type="button" class="btn-secondary" id="btn-send-otp">' +
        escapeHtml(t("sendOtp")) +
        "</button></div>"
      );
    }
    var resendLeft = otpResendSecondsLeft();
    var resendLabel =
      resendLeft > 0
        ? t("resendIn").replace("{n}", String(resendLeft))
        : t("resendOtp");
    return (
      '<div class="auth-form">' +
      '<div class="auth-phone-row">' +
      "<span>" +
      escapeHtml(state.customer.phone) +
      "</span>" +
      '<button type="button" class="link-inline" id="btn-edit-phone">' +
      escapeHtml(t("changePhone")) +
      "</button></div>" +
      '<label>' +
      escapeHtml(t("otp")) +
      '</label><input type="text" id="inp-otp" inputmode="numeric" maxlength="6" autocomplete="one-time-code">' +
      '<div class="auth-actions">' +
      '<button type="button" class="btn-secondary" id="btn-verify-otp">' +
      escapeHtml(t("login")) +
      "</button>" +
      '<button type="button" class="btn-secondary" id="btn-resend-otp"' +
      (resendLeft > 0 ? " disabled" : "") +
      ">" +
      escapeHtml(resendLabel) +
      "</button></div></div>"
    );
  }

  function wireAuthForm() {
    var phoneInp = document.getElementById("inp-phone");
    if (phoneInp) {
      phoneInp.oninput = function () {
        state.customer.phone = formatPhoneInput(phoneInp.value);
        phoneInp.value = state.customer.phone;
      };
    }
    var nameInp = document.getElementById("inp-name");
    if (nameInp) {
      nameInp.oninput = function () {
        state.customer.name = nameInp.value;
      };
    }
    var sendBtn = document.getElementById("btn-send-otp");
    if (sendBtn) {
      sendBtn.onclick = function () {
        sendOtp(false);
      };
    }
    var editPhoneBtn = document.getElementById("btn-edit-phone");
    if (editPhoneBtn) editPhoneBtn.onclick = editPhone;
    var resendBtn = document.getElementById("btn-resend-otp");
    if (resendBtn) resendBtn.onclick = resendOtp;
    var otpInp = document.getElementById("inp-otp");
    var verifyBtn = document.getElementById("btn-verify-otp");
    if (verifyBtn && otpInp) {
      verifyBtn.onclick = function () {
        verifyOtp(otpInp.value.trim());
      };
    }
  }

  function addToCart(dish) {
    var id = dishKey(dish);
    var found = state.cart.find(function (c) {
      return c.f_dish === id;
    });
    if (found) found.f_qty += 1;
    else {
      state.cart.push({
        f_dish: id,
        f_dish_name: dish.f_dish_name,
        f_price: Number(dish.f_price) || 0,
        f_qty: 1
      });
    }
    toast(t("added"));
    bumpCart();
    render();
  }

  function changeQty(dishId, delta) {
    var idx = state.cart.findIndex(function (c) {
      return c.f_dish === dishId;
    });
    if (idx < 0) return;
    state.cart[idx].f_qty += delta;
    if (state.cart[idx].f_qty <= 0) state.cart.splice(idx, 1);
    render();
  }

  function canProceed() {
    if (state.view === V.HOME) return canProceedHome();
    if (state.view === V.VISIT) {
      return !state.visitSlotsLoading && canProceedVisit();
    }
    if (state.view === V.MENU) {
      return state.cart.length > 0 && !state.menuLoading;
    }
    if (state.view === V.CHECKOUT) {
      if (state.customer.verified) return state.cart.length > 0;
      if (state.authStep === "otp") return false;
      return false;
    }
    if (state.view === V.PAYMENT) {
      return (
        state.cart.length > 0 &&
        state.customer.verified &&
        state.policyAgreed
      );
    }
    return false;
  }

  function onNext() {
    if (state.view === V.HOME && canProceedHome()) setView(V.VISIT);
    else if (state.view === V.VISIT && canProceedVisit()) setView(V.MENU);
    else if (state.view === V.MENU && state.cart.length) setView(V.CHECKOUT);
    else if (state.view === V.CHECKOUT && state.customer.verified) setView(V.PAYMENT);
    else if (state.view === V.PAYMENT) submitOrder();
  }

  function renderDishThumb(dish) {
    var img = dish.f_image;
    if (img && String(img).length > 20) {
      var src =
        String(img).indexOf("data:") === 0 ? img : "data:image/jpeg;base64," + img;
      return '<img src="' + escapeAttr(src) + '" alt="">';
    }
    return '<span class="no-img">🚗</span>';
  }

  function statusLabel(code) {
    if (code === 1) return t("statusActive");
    if (code === 2) return t("statusDone");
    if (code === 3) return t("statusCancelled");
    return String(code);
  }

  function policyAgreeBtnLabel() {
    if (state.view === V.HOME) return t("next");
    if (state.view === V.VISIT) return t("services");
    if (state.view === V.MENU) return t("checkout");
    if (state.view === V.CHECKOUT) return t("goPay");
    if (state.view === V.PAYMENT) return t("pay");
    return t("checkout");
  }

  function paymentLogosInnerHtml() {
    return (
      '<img src="assets/cards/arca.svg?v=2" alt="ArCa" width="72" height="48">' +
      '<img src="assets/cards/visa.svg?v=2" alt="Visa" width="72" height="48">' +
      '<img src="assets/cards/mastercard.svg?v=2" alt="Mastercard" width="72" height="48">' +
      '<img src="assets/cards/mir.svg?v=2" alt="MIR" width="72" height="48">'
    );
  }

  function paymentLogosBlockHtml() {
    return (
      '<div class="checkout-pay">' +
      '<p class="checkout-pay-label">' +
      escapeHtml(t("acceptedCards")) +
      "</p>" +
      '<div class="pay-logos" aria-label="ArCa, Visa, Mastercard, MIR">' +
      paymentLogosInnerHtml() +
      "</div></div>"
    );
  }

  function legalHref(page) {
    return state.locale + "/" + page;
  }

  function updateFooterLegalLinks() {
    var map = [
      ["footer-link-terms", "terms", "navTerms"],
      ["footer-link-cancellation", "cancellation", "navCancellation"],
      ["footer-link-privacy", "privacy", "navPrivacy"]
    ];
    map.forEach(function (item) {
      var el = document.getElementById(item[0]);
      if (!el) return;
      el.textContent = t(item[2]);
      el.setAttribute("href", legalHref(item[1]));
    });
  }

  function openLegal(page) {
    var view = LEGAL_PATHS[page] || V.PRIVACY;
    if (!isLegalView(state.view)) {
      state.policyReturnView = state.view;
    }
    setView(view, { pushUrl: true });
  }

  function wireLegalLinks(root) {
    (root || document).querySelectorAll("[data-legal]").forEach(function (el) {
      el.onclick = function (e) {
        e.preventDefault();
        e.stopPropagation();
        openLegal(el.getAttribute("data-legal"));
      };
    });
  }

  function renderActionPolicy() {
    if (!els.actionPolicyAgree) return;
    var showAction =
      state.view === V.HOME ||
      state.view === V.VISIT ||
      state.view === V.MENU ||
      (state.view === V.CHECKOUT && state.customer.verified) ||
      state.view === V.PAYMENT;
    if (!showAction || isLegalView(state.view)) {
      els.actionPolicyAgree.innerHTML = "";
      els.actionPolicyAgree.hidden = true;
      return;
    }
    els.actionPolicyAgree.hidden = false;
    els.actionPolicyAgree.innerHTML = renderPolicyAgreeBlock(
      "policy-agree-action",
      "link-policy-action",
      policyAgreeBtnLabel()
    );
    wirePolicyAgree("policy-agree-action", "link-policy-action");
  }

  function renderShell() {
    if (els.langSelect) els.langSelect.value = state.locale;
    if (els.btnAccount) {
      var accountLabel = state.customer.verified ? t("account") : t("login");
      els.btnAccount.setAttribute("aria-label", accountLabel);
      els.btnAccount.title = accountLabel;
    }
    els.footerYear.textContent = String(new Date().getFullYear());
    if (els.footerEntity) {
      els.footerEntity.textContent =
        t("companyName") + " · " + t("tinLabel") + " " + COMPANY_TIN;
    }
    if (els.footerAddress) {
      els.footerAddress.textContent =
        t("addressLabel") + ": " + t("companyAddress");
    }
    els.footerPhone.textContent = CONTACT_PHONE;
    els.footerPhone.href = "tel:" + CONTACT_PHONE.replace(/\s/g, "");
    els.footerEmail.textContent = CONTACT_EMAIL;
    els.footerEmail.href = "mailto:" + CONTACT_EMAIL;
    if (els.footerCards) els.footerCards.innerHTML = paymentLogosInnerHtml();
    updateFooterLegalLinks();
    renderActionPolicy();

    var total = cartTotal();
    if (total > 0 && els.cartBadge) {
      els.cartBadge.hidden = false;
      els.cartBadge.textContent = formatCartBadge(total);
    } else if (els.cartBadge) {
      els.cartBadge.hidden = true;
    }
    if (els.btnCart) els.btnCart.classList.toggle("cart-bump", state.cartBump);
    updateActionBar();
  }

  function renderHome() {
    if (state.catalogLoading && state.cars.length === 0) {
      els.main.innerHTML =
        '<div class="loading">' + escapeHtml(t("loading")) + "</div>";
      return;
    }

    var html =
      '<h2 class="section-title">' + escapeHtml(t("chooseCar")) + "</h2>";

    if (state.catalogError) {
      html +=
        '<p class="stub-note">' +
        escapeHtml(state.catalogError) +
        "</p>";
    }
    if (state.menuError) {
      html +=
        '<p class="stub-note">' +
        escapeHtml(t("menuErr")) +
        ": " +
        escapeHtml(state.menuError) +
        "</p>";
    }

    html +=
      '<div class="picker-section' +
      (state.customMode ? " is-disabled" : "") +
      '">' +
      '<h3 class="sub-title">' +
      escapeHtml(t("chooseBrand")) +
      "</h3>" +
      '<div class="picker-block">' +
      '<div class="picker-filter-row">' +
      '<input type="text" class="picker-filter" id="brand-filter" autocomplete="off" placeholder="' +
      escapeAttr(t("filterPlaceholder")) +
      '" value="' +
      escapeAttr(state.brandFilter) +
      '"' +
      (state.customMode ? " disabled" : "") +
      '">' +
      '<button type="button" class="picker-clear" id="brand-clear" aria-label="' +
      escapeAttr(t("clear")) +
      '"' +
      (state.customMode ? " disabled" : "") +
      ">×</button></div>" +
      '<ul class="picker-list" id="brand-list">';

    state.cars.forEach(function (car) {
      var sel =
        state.carBrandId && String(state.carBrandId) === String(car.f_id)
          ? " selected"
          : "";
      html +=
        "<li><button type=\"button\" class=\"picker-item" +
        sel +
        '" data-id="' +
        escapeAttr(String(car.f_id)) +
        '" data-name="' +
        escapeAttr(car.f_name) +
        '">' +
        escapeHtml(car.f_name) +
        "</button></li>";
    });
    html += "</ul></div></div>";

    var brandModels = modelsForBrand(state.carBrandId);
    var modelSectionDisabled = state.customMode || !state.carBrandId;
    html +=
      '<div class="picker-section' +
      (modelSectionDisabled ? " is-disabled" : "") +
      '">' +
      '<h3 class="sub-title">' +
      escapeHtml(t("chooseModel")) +
      "</h3>" +
      '<div class="picker-block">' +
      '<div class="picker-filter-row">' +
      '<input type="text" class="picker-filter" id="model-filter" autocomplete="off" placeholder="' +
      escapeAttr(t("filterPlaceholder")) +
      '" value="' +
      escapeAttr(state.modelFilter) +
      '"' +
      (modelSectionDisabled ? " disabled" : "") +
      '">' +
      '<button type="button" class="picker-clear" id="model-clear" aria-label="' +
      escapeAttr(t("clear")) +
      '"' +
      (modelSectionDisabled ? " disabled" : "") +
      ">×</button></div>" +
      '<ul class="picker-list" id="model-list">';

    if (state.modelsLoading && state.carBrandId) {
      html +=
        '<li class="picker-empty picker-loading">' +
        escapeHtml(t("loading")) +
        "</li>";
    } else if (state.modelsError && state.carBrandId) {
      html +=
        '<li class="picker-empty">' +
        escapeHtml(state.modelsError) +
        "</li>";
    } else if (state.carBrandId && brandModels.length > 0) {
      brandModels.forEach(function (model) {
        var sel =
          state.carModelId && String(state.carModelId) === String(model.f_id)
            ? " selected"
            : "";
        html +=
          "<li><button type=\"button\" class=\"picker-item" +
          sel +
          '" data-id="' +
          escapeAttr(String(model.f_id)) +
          '" data-name="' +
          escapeAttr(model.f_name) +
          '">' +
          escapeHtml(model.f_name) +
          "</button></li>";
      });
    } else if (
      state.carBrandId &&
      !state.modelsLoading &&
      brandModels.length === 0
    ) {
      html +=
        '<li class="picker-empty">' + escapeHtml(t("noModels")) + "</li>";
    }
    html += "</ul></div></div>";

    html +=
      '<label class="custom-option-label">' +
      '<input type="checkbox" id="custom-mode-check"' +
      (state.customMode ? " checked" : "") +
      "> " +
      escapeHtml(t("customOption")) +
      "</label>";

    html +=
      '<div class="custom-panel' +
      (state.customMode ? "" : " hidden") +
      '">' +
      '<label class="field-label" for="custom-text">' +
      escapeHtml(t("customLabel")) +
      "</label>" +
      '<input type="text" class="field-input" id="custom-text" autocomplete="off" value="' +
      escapeAttr(state.customText) +
      '">' +
      '<p class="section-hint">' +
      escapeHtml(t("chooseType")) +
      "</p>" +
      '<div class="type-pick-row">';

    CAR_TYPES.forEach(function (typeId) {
      var sel = state.manualType === typeId ? " selected" : "";
      html +=
        '<button type="button" class="type-pick-btn' +
        sel +
        '" data-type="' +
        typeId +
        '">' +
        escapeHtml(carTypeName(typeId)) +
        "</button>";
    });
    html += "</div></div>";

    var effType = getEffectiveCarType();
    if (effType) {
      html +=
        '<div class="car-summary">' +
        escapeHtml(t("youSelected")) +
        ": <strong>" +
        escapeHtml(carTypeName(effType)) +
        "</strong></div>";
    }

    els.main.innerHTML = html;
    wireHomePickers();
  }

  function renderVisitSection() {
    var maxOffset = VISIT_DAYS_AHEAD - 1;
    var canPrev = state.visitDateOffset > 0;
    var canNext = state.visitDateOffset < maxOffset;
    var html =
      '<section class="visit-panel" aria-label="' +
      escapeAttr(t("visitTitle")) +
      '">' +
      '<div class="visit-date-nav">' +
      '<button type="button" class="visit-date-btn" id="visit-date-prev" aria-label="' +
      escapeAttr(t("back")) +
      '"' +
      (canPrev ? "" : " disabled") +
      ">◀</button>" +
      '<span class="visit-date-label" id="visit-date-label">' +
      escapeHtml(formatVisitDateLabel(state.visitDateOffset)) +
      "</span>" +
      '<button type="button" class="visit-date-btn" id="visit-date-next" aria-label="' +
      escapeAttr(t("next")) +
      '"' +
      (canNext ? "" : " disabled") +
      ">▶</button></div>";

    if (state.visitSlotsLoading) {
      html +=
        '<div class="visit-no-slots">' + escapeHtml(t("loading")) + "</div>";
    } else if (!state.visitSlots.length) {
      html +=
        '<div class="visit-no-slots">' +
        escapeHtml(t("visitNoSlots")) +
        "</div>";
    } else {
      html +=
        '<div class="time-wheel-wrap">' +
        '<div class="time-wheel-highlight" aria-hidden="true"></div>' +
        '<div class="time-wheel-viewport" id="time-wheel-viewport">' +
        '<div class="time-wheel-list" id="time-wheel-list" tabindex="0" role="listbox" aria-label="' +
        escapeAttr(t("visitAt")) +
        '">';
      state.visitSlots.forEach(function (slot) {
        var sel = slot === state.visitTime ? " is-center" : "";
        html +=
          '<div class="time-wheel-item' +
          sel +
          '" data-time="' +
          escapeAttr(slot) +
          '" role="option">' +
          escapeHtml(slot) +
          "</div>";
      });
      html += "</div></div></div>";
    }
    html += "</section>";
    return html;
  }

  function updateActionBar() {
    var showAction =
      state.view === V.HOME ||
      state.view === V.VISIT ||
      state.view === V.MENU ||
      (state.view === V.CHECKOUT && state.customer.verified) ||
      state.view === V.PAYMENT;
    if (els.actionBar) els.actionBar.hidden = !showAction;
    if (!els.actionBar || els.actionBar.hidden || !els.btnNext) return;
    els.btnNext.disabled = !canProceed();
    if (state.view === V.HOME) els.btnNext.textContent = t("next");
    else if (state.view === V.VISIT) els.btnNext.textContent = t("services");
    else if (state.view === V.MENU) els.btnNext.textContent = t("checkout");
    else if (state.view === V.CHECKOUT) els.btnNext.textContent = t("goPay");
    else if (state.view === V.PAYMENT) els.btnNext.textContent = t("pay");
  }

  function wireVisitPicker() {
    var prev = document.getElementById("visit-date-prev");
    var next = document.getElementById("visit-date-next");
    if (prev) {
      prev.onclick = function () {
        if (state.visitDateOffset <= 0) return;
        state.visitDateOffset -= 1;
        loadVisitSlotsForCurrentDate().then(render);
      };
    }
    if (next) {
      next.onclick = function () {
        if (state.visitDateOffset >= VISIT_DAYS_AHEAD - 1) return;
        state.visitDateOffset += 1;
        loadVisitSlotsForCurrentDate().then(render);
      };
    }

    var viewport = document.getElementById("time-wheel-viewport");
    var list = document.getElementById("time-wheel-list");
    if (!viewport || !list) return;

    var scrollTimer = null;
    var itemH = 44;

    function syncWheelSelection(snap) {
      var items = list.querySelectorAll(".time-wheel-item");
      if (!items.length) return;
      var centerY = viewport.getBoundingClientRect().top + viewport.clientHeight / 2;
      var best = null;
      var bestDist = Infinity;
      items.forEach(function (el) {
        var r = el.getBoundingClientRect();
        var cy = r.top + r.height / 2;
        var dist = Math.abs(cy - centerY);
        el.classList.remove("is-center");
        if (dist < bestDist) {
          bestDist = dist;
          best = el;
        }
      });
      if (!best) return;
      best.classList.add("is-center");
      var tval = best.getAttribute("data-time");
      if (tval && tval !== state.visitTime) {
        state.visitTime = tval;
        updateActionBar();
      }
      if (snap) {
        var idx = Array.prototype.indexOf.call(items, best);
        list.scrollTo({ top: idx * itemH, behavior: "smooth" });
      }
    }

    list.addEventListener("scroll", function () {
      clearTimeout(scrollTimer);
      syncWheelSelection(false);
      scrollTimer = setTimeout(function () {
        syncWheelSelection(true);
      }, 120);
    });

    var startIdx = Math.max(0, state.visitSlots.indexOf(state.visitTime));
    list.scrollTop = startIdx * itemH;
    requestAnimationFrame(function () {
      syncWheelSelection(false);
    });
  }

  function renderVisit() {
    var html =
      '<button type="button" class="link-back" id="link-back">' +
      escapeHtml(t("back")) +
      "</button>" +
      '<h2 class="section-title">' +
      escapeHtml(t("visitTitle")) +
      "</h2>" +
      '<p class="section-hint visit-car-hint">' +
      escapeHtml(carMenuTitle()) +
      "</p>" +
      renderVisitSection();
    els.main.innerHTML = html;
    var back = document.getElementById("link-back");
    if (back) {
      back.onclick = function () {
        setView(V.HOME);
      };
    }
    wireVisitPicker();
  }

  function renderMenu() {
    if (state.menuLoading) {
      els.main.innerHTML =
        '<button type="button" class="link-back" id="link-back">' +
        escapeHtml(t("back")) +
        "</button>" +
        '<div class="loading">' +
        escapeHtml(t("loading")) +
        "</div>";
      var backLoading = document.getElementById("link-back");
      if (backLoading) {
        backLoading.onclick = function () {
          setView(V.VISIT);
        };
      }
      return;
    }

    var dishes = dishesForCarType();
    var html =
      '<button type="button" class="link-back" id="link-back">' +
      escapeHtml(t("back")) +
      "</button>" +
      '<h2 class="section-title">' +
      escapeHtml(carMenuTitle()) +
      "</h2>" +
      '<p class="section-hint">' +
      escapeHtml(t("tapToAdd")) +
      "</p>";
    if (dishes.length === 0) {
      html += '<div class="empty">' + escapeHtml(t("emptyCart")) + "</div>";
    } else {
      html += '<div class="menu-list">';
      dishes.forEach(function (d) {
        var id = dishKey(d);
        html +=
          '<article class="dish-card" data-dish-id="' +
          escapeAttr(id) +
          '">' +
          '<div class="dish-thumb">' +
          renderDishThumb(d) +
          "</div>" +
          '<div class="dish-info"><h3>' +
          escapeHtml(d.f_dish_name || "") +
          "</h3></div>" +
          '<div class="dish-price">' +
          fmtMoney(d.f_price) +
          "</div></article>";
      });
      html += "</div>";
    }
    els.main.innerHTML = html;
    var back = document.getElementById("link-back");
    if (back) back.onclick = function () {
      setView(V.VISIT);
    };
    els.main.querySelectorAll(".dish-card").forEach(function (card) {
      card.onclick = function () {
        var id = card.getAttribute("data-dish-id");
        var dish = dishes.find(function (d) {
          return dishKey(d) === id;
        });
        if (dish) addToCart(dish);
      };
    });
  }

  function renderCheckout() {
    var html =
      '<button type="button" class="link-back" id="link-back">' +
      escapeHtml(t("back")) +
      "</button>" +
      '<h2 class="section-title">' +
      escapeHtml(t("checkout")) +
      "</h2>";

    if (!state.customer.verified) {
      html += renderAuthFormHtml();
    }

    html +=
      '<div class="cart-total"><span>' +
      escapeHtml(t("total")) +
      "</span><span>" +
      fmtMoney(cartTotal()) +
      "</span></div>";
    if (state.cart.length === 0) {
      html += '<div class="empty">' + escapeHtml(t("emptyCart")) + "</div>";
    } else {
      html += '<div class="cart-list">';
      state.cart.forEach(function (c) {
        html +=
          '<div class="cart-row">' +
          '<div class="cart-row-name">' +
          escapeHtml(c.f_dish_name) +
          "</div>" +
          '<div class="qty-controls">' +
          '<button type="button" class="qty-btn" data-q="-1" data-id="' +
          escapeAttr(c.f_dish) +
          '">−</button><span>' +
          c.f_qty +
          '</span><button type="button" class="qty-btn" data-q="1" data-id="' +
          escapeAttr(c.f_dish) +
          '">+</button></div>' +
          '<div class="cart-row-price">' +
          fmtMoney(c.f_price * c.f_qty) +
          "</div></div>";
      });
      html += "</div>";
    }
    html += paymentLogosBlockHtml();
    els.main.innerHTML = html;

    var back = document.getElementById("link-back");
    if (back) back.onclick = function () {
      setView(V.MENU);
    };

    wireAuthForm();

    els.main.querySelectorAll(".qty-btn").forEach(function (btn) {
      btn.onclick = function () {
        changeQty(
          btn.getAttribute("data-id"),
          parseInt(btn.getAttribute("data-q"), 10)
        );
      };
    });

    if (state.authStep === "otp" && !state.customer.verified) {
      startOtpTicker();
    }
  }

  function legalDoc(page) {
    var pack = LEGAL[page] || LEGAL.privacy;
    return pack[state.locale] || pack.en;
  }

  function renderLegalContactsSection() {
    var phoneHref = "tel:" + CONTACT_PHONE.replace(/\s/g, "");
    return (
      '<section class="policy-section"><h3>' +
      escapeHtml(t("contactsTitle")) +
      "</h3>" +
      "<p><strong>" +
      escapeHtml(t("companyName")) +
      "</strong></p>" +
      "<p><strong>" +
      escapeHtml(t("tinLabel")) +
      ":</strong> " +
      escapeHtml(COMPANY_TIN) +
      "</p>" +
      "<p><strong>" +
      escapeHtml(t("addressLabel")) +
      ":</strong> " +
      escapeHtml(t("companyAddress")) +
      "</p>" +
      "<p><strong>" +
      escapeHtml(t("phone")) +
      ':</strong> <a href="' +
      escapeAttr(phoneHref) +
      '">' +
      escapeHtml(CONTACT_PHONE) +
      "</a></p>" +
      "<p><strong>" +
      escapeHtml(t("emailLabel")) +
      ':</strong> <a href="mailto:' +
      escapeAttr(CONTACT_EMAIL) +
      '">' +
      escapeHtml(CONTACT_EMAIL) +
      "</a></p>" +
      "<p>https://" +
      escapeHtml(COMPANY_SITE) +
      "</p></section>"
    );
  }

  function renderLegalSection(sec) {
    var html =
      '<section class="policy-section"><h3>' +
      escapeHtml(sec.title) +
      "</h3>";
    (sec.paragraphs || []).forEach(function (p) {
      html += "<p>" + escapeHtml(p) + "</p>";
    });
    if (sec.list && sec.list.length) {
      html += '<ul class="policy-list">';
      sec.list.forEach(function (item) {
        html += "<li>" + escapeHtml(item) + "</li>";
      });
      html += "</ul>";
    }
    html += "</section>";
    return html;
  }

  function renderLegal() {
    var page =
      state.view === V.TERMS
        ? "terms"
        : state.view === V.CANCELLATION
          ? "cancellation"
          : "privacy";
    var doc = legalDoc(page);
    var returnView = state.policyReturnView || V.HOME;
    var html =
      '<button type="button" class="link-back" id="link-back">' +
      escapeHtml(t("back")) +
      "</button>" +
      '<h2 class="section-title">' +
      escapeHtml(doc.title) +
      '</h2><article class="policy-doc">' +
      renderLegalContactsSection();
    (doc.sections || []).forEach(function (sec) {
      html += renderLegalSection(sec);
    });
    html += "</article>";
    els.actionBar.hidden = true;
    els.main.innerHTML = html;
    document.getElementById("link-back").onclick = function () {
      setView(isLegalView(returnView) ? V.HOME : returnView);
    };
  }

  function legalAgreeLink(page, labelKey) {
    return (
      '<button type="button" class="policy-agree-link" data-legal="' +
      escapeAttr(page) +
      '">' +
      escapeHtml(t(labelKey)) +
      "</button>"
    );
  }

  function renderPolicyAgreeHtml(btnLabel) {
    return (
      escapeHtml(t("policyAgreeBefore")) +
      "<strong>" +
      escapeHtml(btnLabel) +
      "</strong>" +
      escapeHtml(t("policyAgreeAfter")) +
      legalAgreeLink("terms", "navTerms") +
      escapeHtml(t("policyAgreeSep")) +
      legalAgreeLink("cancellation", "navCancellation") +
      escapeHtml(t("policyAgreeAnd")) +
      legalAgreeLink("privacy", "navPrivacy") +
      escapeHtml(t("policyAgreeEnd"))
    );
  }

  function renderPolicyAgreeBlock(checkboxId, linkId, btnLabel) {
    return (
      '<label class="policy-agree">' +
      '<input type="checkbox" id="' +
      escapeAttr(checkboxId) +
      '"' +
      (state.policyAgreed ? " checked" : "") +
      ">" +
      "<span>" +
      renderPolicyAgreeHtml(btnLabel) +
      "</span></label>"
    );
  }

  function wirePolicyAgree(checkboxId, linkId) {
    var policyAgree = document.getElementById(checkboxId);
    var wrap = policyAgree && policyAgree.closest ? policyAgree.closest("label") : null;
    wireLegalLinks(wrap || document.getElementById("action-policy-agree"));
    if (policyAgree) {
      policyAgree.onchange = function () {
        state.policyAgreed = policyAgree.checked;
        renderShell();
      };
    }
  }

  function renderPayment() {
    var html =
      '<button type="button" class="link-back" id="link-back">' +
      escapeHtml(t("back")) +
      "</button>" +
      '<h2 class="section-title">' +
      escapeHtml(t("pay")) +
      "</h2>" +
      '<div class="cart-total"><span>' +
      escapeHtml(t("total")) +
      "</span><span>" +
      fmtMoney(cartTotal()) +
      "</span></div>" +
      '<div class="cart-list">';
    state.cart.forEach(function (c) {
      html +=
        '<div class="cart-row">' +
        '<div class="cart-row-name">' +
        escapeHtml(c.f_dish_name) +
        " × " +
        c.f_qty +
        "</div>" +
        '<div class="cart-row-price">' +
        fmtMoney(c.f_price * c.f_qty) +
        "</div></div>";
    });
    html += "</div>" + paymentLogosBlockHtml();
    els.main.innerHTML = html;
    document.getElementById("link-back").onclick = function () {
      setView(V.CHECKOUT);
    };
  }

  function renderProfile() {
    var returnView = state.profileReturnView || V.HOME;
    var title = state.customer.verified ? t("account") : t("login");
    var html =
      '<button type="button" class="link-back" id="link-back">' +
      escapeHtml(t("back")) +
      "</button>" +
      '<h2 class="section-title">' +
      escapeHtml(title) +
      "</h2>";

    if (!state.customer.verified) {
      html += renderAuthFormHtml();
    } else {
      html +=
        '<div class="profile-card">' +
        '<div class="profile-row"><span class="profile-label">' +
        escapeHtml(t("name")) +
        '</span><span class="profile-value">' +
        escapeHtml(state.customer.name) +
        "</span></div>" +
        '<div class="profile-row"><span class="profile-label">' +
        escapeHtml(t("phone")) +
        '</span><span class="profile-value">' +
        escapeHtml(formatPhoneInput(state.customer.phone || "")) +
        "</span></div></div>" +
        '<div class="account-menu">' +
        '<button type="button" class="btn-account-action" id="btn-goto-orders">' +
        escapeHtml(t("orders")) +
        "</button>" +
        '<button type="button" class="btn-logout" id="btn-logout">' +
        escapeHtml(t("logout")) +
        "</button></div>";
    }

    els.main.innerHTML = html;

    document.getElementById("link-back").onclick = function () {
      setView(returnView);
    };
    wireAuthForm();
    var ordersBtn = document.getElementById("btn-goto-orders");
    if (ordersBtn) {
      ordersBtn.onclick = function () {
        setView(V.ORDERS);
      };
    }
    var logoutBtn = document.getElementById("btn-logout");
    if (logoutBtn) logoutBtn.onclick = logout;

    if (state.authStep === "otp" && !state.customer.verified) {
      startOtpTicker();
    }
  }

  function renderOrders() {
    var html =
      '<button type="button" class="link-back" id="link-back">' +
      escapeHtml(t("back")) +
      "</button>" +
      '<h2 class="section-title">' +
      escapeHtml(t("orders")) +
      "</h2>";

    function block(title, list) {
      var s = '<h3 class="sub-title">' + escapeHtml(title) + "</h3>";
      if (!list || !list.length) {
        s += '<div class="empty">' + escapeHtml(t("noOrders")) + "</div>";
        return s;
      }
      s += '<div class="orders-list">';
      list.forEach(function (o) {
        s +=
          '<div class="order-card">' +
          '<div class="order-head"><span>#' +
          o.f_id +
          "</span><span>" +
          escapeHtml(statusLabel(o.f_status)) +
          "</span></div>" +
          '<div class="order-meta">' +
          escapeHtml(String(o.f_date || "")) +
          "</div>";
        if (o.visit) {
          var visitText = formatVisitDisplay(o.visit);
          if (visitText) {
            s +=
              '<div class="order-meta">' +
              escapeHtml(t("visitAt")) +
              ": " +
              escapeHtml(visitText) +
              "</div>";
          }
        }
        s +=
          '<div class="order-total">' +
          fmtMoney(o.total) +
          "</div></div>";
      });
      s += "</div>";
      return s;
    }

    html += block(t("activeOrders"), state.orders.active);
    html += block(t("historyOrders"), state.orders.history);
    els.main.innerHTML = html;
    document.getElementById("link-back").onclick = function () {
      setView(V.PROFILE);
    };
  }

  function renderSuccess() {
    els.actionBar.hidden = true;
    els.main.innerHTML =
      '<div class="success-panel">' +
      '<div class="ok-icon">✅</div>' +
      "<h2>" +
      escapeHtml(t("thankYou")) +
      "</h2>" +
      "<p>" +
      escapeHtml(t("orderAccepted")) +
      (state.lastOrderId ? " #" + state.lastOrderId : "") +
      "</p>" +
      '<p class="section-hint">' +
      fmtMoney(state.lastOrderTotal) +
      "</p>" +
      '<button type="button" class="btn-secondary" id="btn-new">' +
      escapeHtml(t("newOrder")) +
      "</button></div>";
    document.getElementById("btn-new").onclick = function () {
      resetCarSelection();
      state.cart = [];
      state.lastOrderId = null;
      setView(V.HOME);
    };
  }

  function render() {
    renderShell();
    if (state.view === V.HOME) renderHome();
    else if (state.view === V.VISIT) renderVisit();
    else if (state.view === V.MENU) renderMenu();
    else if (state.view === V.CHECKOUT) renderCheckout();
    else if (state.view === V.PAYMENT) renderPayment();
    else if (state.view === V.ORDERS) renderOrders();
    else if (state.view === V.PROFILE) renderProfile();
    else if (isLegalView(state.view)) renderLegal();
    else if (state.view === V.SUCCESS) renderSuccess();
  }

  function init() {
    ensureLocaleInUrl();

    window.addEventListener("popstate", function () {
      var route = routeFromPath();
      if (route.locale && route.locale !== state.locale) {
        setLocaleFromSelect(route.locale);
        return;
      }
      var nextView = route.view || V.HOME;
      if (nextView !== state.view) {
        state.view = nextView;
        render();
      }
    });

    els.main = document.getElementById("main");
    els.actionBar = document.getElementById("action-bar");
    els.btnNext = document.getElementById("btn-next");
    els.langSelect = document.getElementById("lang-select");
    els.btnAccount = document.getElementById("btn-account");
    els.btnCart = document.getElementById("btn-cart");
    els.cartBadge = document.getElementById("cart-badge");
    els.toast = document.getElementById("toast");
    els.footerYear = document.getElementById("footer-year");
    els.footerEntity = document.getElementById("footer-entity");
    els.footerAddress = document.getElementById("footer-address");
    els.footerPhone = document.getElementById("footer-phone");
    els.footerEmail = document.getElementById("footer-email");
    els.footerCards = document.getElementById("footer-cards");
    els.actionPolicyAgree = document.getElementById("action-policy-agree");

    els.btnNext.onclick = onNext;
    if (els.langSelect) {
      els.langSelect.onchange = function () {
        setLocaleFromSelect(els.langSelect.value);
      };
    }
    document.getElementById("btn-home").onclick = goHome;
    if (els.btnAccount) els.btnAccount.onclick = openAccount;
    els.btnCart.onclick = function () {
      if (state.cart.length) setView(V.CHECKOUT);
      else toast(t("emptyCart"));
    };
    wireLegalLinks(document.querySelector(".site-footer-legal"));

    render();
    Promise.all([fetchCatalog(), fetchMenu()]).then(function () {
      render();
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
