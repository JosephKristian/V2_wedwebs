import 'package:flutter/material.dart';

class AppStylesNew {
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 150, 20, 20);

  static const TextStyle loginButtonText = TextStyle(
    color: Colors.white,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  );

  static const InputDecoration emailInputDecoration = InputDecoration(
    labelText: 'Email',
    labelStyle: TextStyle(color: AppColors.captionColor),
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: Color.fromARGB(255, 205, 193, 164), // Warna border default
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.iconColor, // Warna border saat TextField aktif
        width: 1.0, // Lebar border saat tidak difokuskan
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.iconColor,
        width: 2.0, // Lebar border saat difokuskan
      ),
    ),
  );

  static InputDecoration passwordInputDecoration(
      bool obscurePassword, VoidCallback togglePasswordVisibility) {
    return InputDecoration(
      labelText: 'Password',
      labelStyle: TextStyle(color: AppColors.captionColor),
      border: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.iconColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.iconColor, // Warna border saat TextField aktif
          width: 1.0, // Lebar border saat tidak difokuskan
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.iconColor,
          width: 2.0, // Lebar border saat difokuskan
        ),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscurePassword ? Icons.visibility : Icons.visibility_off,
          color: AppColors.iconColor,
        ),
        onPressed: togglePasswordVisibility,
      ),
    );
  }
}

class AppColors {
  // Existing Colors
  static const Color backgroundColor = Color.fromARGB(255, 223, 195, 112);
  static const Color gradientStartColor = Colors.black87;
  static final Color gradientEndColor = Colors.teal.shade300.withOpacity(0.6);
  static const Color buttonColor = Colors.white70;
  static const Color textColor = Colors.white70;
  static const Color appBarColor = Color.fromARGB(255, 31, 29, 21); // BlackGrey
  static const Color drawerHeaderColor =
      Color.fromARGB(255, 31, 29, 21); // BlackGrey
  static const Color iconColor = Color.fromARGB(255, 203, 170, 92);
  static const Color dividerColor = Colors.grey;
  static const Color bottomAppBarColor =
      Color.fromARGB(255, 31, 29, 21); // BlackGrey
  static const Color selectedItemColor =
      Color.fromARGB(255, 223, 195, 112); // Gold
  static const Color unselectedItemColor = Colors.white;

  // New Colors for Snackbar
  static const Color snackBarSuccessColor =
      Color.fromARGB(255, 76, 175, 80); // Green
  static const Color snackBarErrorColor =
      Color.fromARGB(255, 244, 67, 54); // Red

  // New Getters for Consistent UI
  static const Color selectedCardColor =
      Color.fromARGB(255, 200, 162, 112); // Adjusted Gold
  static const Color cardColor = Colors.white70;
  static const Color selectedCaptionColor = Colors.black87;
  static const Color captionColor = Colors.black54;
  static const Color iconColorWarning = Color.fromARGB(255, 193, 80, 72);
  static const Color iconColorEdit = Colors.blueGrey;
}

class IconButtonGoldList extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;

  IconButtonGoldList({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50.0), // Menggunakan bentuk bulat
      child: Card(
        color: Color.fromARGB(255, 46, 45, 39), // Outer color
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(18.10), // Sesuaikan dengan bentuk bulat
        ),
        elevation: 10,
        child: IconButton(
          icon: Icon(icon),
          color: color,
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      ),
    );
  }
}

class CardTicketMini extends StatelessWidget {
  final String headerText;
  final Widget title;
  final Widget subtitle;
  final Widget? trailing;

  const CardTicketMini({
    Key? key,
    required this.headerText,
    required this.title,
    required this.subtitle,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1), // changes position of shadow
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headerText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 4),
            title,
            SizedBox(height: 4),
            subtitle,
            if (trailing != null) ...[
              SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CardPrimary extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget? trailing;
  final VoidCallback? onTap; // Tambahkan parameter onTap

  CardPrimary({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap, // Tambahkan ke constructor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color.fromARGB(255, 31, 29, 21), // Warna kartu
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.0),
        title: DefaultTextStyle(
          style: TextStyle(color: Colors.white70), // Warna teks di dalam kartu
          child: title,
        ),
        subtitle: DefaultTextStyle(
          style: TextStyle(color: Colors.white70), // Warna teks di dalam kartu
          child: subtitle,
        ),
        trailing: trailing,
        onTap: onTap, // Pindahkan onTap ke sini
      ),
    );
  }
}

class CardTicket extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? headerText;
  final Widget? leadingIcon; // Tambahkan leadingIcon opsional
  final Widget? trailingWidget; // Tambahkan trailingWidget opsional

  CardTicket({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.headerText,
    this.leadingIcon, // Tambahkan ke constructor
    this.trailingWidget, // Tambahkan ke constructor
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: AppColors.appBarColor, // Warna latar belakang tiket
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.all(16.0),
              leading: leadingIcon, // leadingIcon opsional
              title: DefaultTextStyle(
                style: TextStyle(color: Colors.white),
                child: title,
              ),
              subtitle: DefaultTextStyle(
                style: TextStyle(color: Colors.white70),
                overflow: TextOverflow.ellipsis,
                child: subtitle,
              ),
              trailing: trailingWidget ?? trailing, // trailingWidget opsional
            ),
          ],
        ),
      ),
    );
  }
}

class CardGift extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? headerText;
  final Widget? leadingIcon;
  final Widget? trailingWidget;

  CardGift({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.headerText,
    this.leadingIcon,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: AppColors.iconColor, // Warna latar belakang amplop
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              BorderSide(color: Colors.brown, width: 2), // Garis seperti amplop
        ),
        child: Column(
          children: [
            if (headerText != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  headerText!,
                  style: TextStyle(
                    color: Colors.brown,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.all(16.0),
              leading: leadingIcon,
              title: DefaultTextStyle(
                style:
                    TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
                child: title,
              ),
              subtitle: DefaultTextStyle(
                style: TextStyle(color: Colors.brown[700]),
                overflow: TextOverflow.ellipsis,
                child: subtitle,
              ),
              trailing: trailingWidget ?? trailing,
            ),
          ],
        ),
      ),
    );
  }
}

class CardPrimaryWithoutTitle extends StatelessWidget {
  final Widget subtitle;
  final Widget? trailing;
  final VoidCallback? onTap; // Parameter onTap

  CardPrimaryWithoutTitle({
    required this.subtitle,
    this.trailing,
    this.onTap, // Tambahkan ke constructor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color.fromARGB(255, 31, 29, 21), // Warna kartu
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.0),
        subtitle: DefaultTextStyle(
          style: TextStyle(color: Colors.white70), // Warna teks di dalam kartu
          child: subtitle,
        ),
        trailing: trailing,
        onTap: onTap, // Pindahkan onTap ke sini
      ),
    );
  }
}

class StatCardCustom extends StatelessWidget {
  final String title;
  final String value;
  final String valuePax;
  final Color cardColor;
  final double elevation;
  final double borderRadius;
  final VoidCallback? onTap;

  StatCardCustom({
    required this.title,
    required this.value,
    this.valuePax = '-',
    this.cardColor = AppColors.appBarColor,
    this.elevation = 5.0,
    this.borderRadius = 20.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.5; // Sesuaikan lebar card
        final cardHeight =
            constraints.maxHeight * 0.35; // Sesuaikan tinggi card

        return GestureDetector(
          onTap: onTap,
          child: Card(
            margin: EdgeInsets.symmetric(
                horizontal:
                    cardWidth * 0.05), // Padding luar lebih proporsional
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: elevation,
            color: cardColor,
            child: Padding(
              padding: EdgeInsets.all(
                  cardHeight * 0.2), // Padding dalam yang lebih proporsional
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // Tata letak yang seragam
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: cardHeight *
                          0.25, // Ukuran font dinamis sesuai tinggi card
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$valuePax pax',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: cardHeight *
                          0.22, // Ukuran font value lebih kecil dari title
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$value list',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: cardHeight *
                          0.2, // Ukuran font untuk valuePax sedikit lebih kecil
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class StatCardAngpau extends StatelessWidget {
  final String title;
  final String angpauCount;
  final String totalAmount;
  final Color cardColor;
  final double elevation;
  final double borderRadius;
  final VoidCallback? onTap;

  StatCardAngpau({
    required this.title,
    required this.angpauCount,
    this.totalAmount = '',
    this.cardColor = const Color(0xFFF4A460), // Warna khas untuk angpau
    this.elevation = 5.0,
    this.borderRadius = 20.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.9;
        final cardHeight =
            constraints.maxHeight * 0.4; // Tambah tinggi untuk efek amplop

        return GestureDetector(
          onTap: onTap,
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: cardWidth * 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: elevation,
            color: Colors
                .transparent, // Membuat Card transparan agar border terlihat jelas
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.redAccent, // Warna border angpau
                  width: 2.0,
                ),
              ),
              padding: EdgeInsets.all(cardHeight * 0.15),
              child: Stack(
                children: [
                  // Efek lipatan di bagian atas
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: cardHeight * 0.2,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(borderRadius),
                          topRight: Radius.circular(borderRadius),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: cardHeight * 0.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: cardHeight * 0.05), // Jarak antar teks
                        Text(
                          '$angpauCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: cardHeight * 0.30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: cardHeight * 0.05),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// AppStyles Class
class AppStyles {
  static final Shader textGradientShader = LinearGradient(
    colors: <Color>[
      AppColors.appBarColor, // Warna emas terang
      AppColors.iconColor, // Warna emas sedikit gelap
    ],
  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

  // Card Decoration
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.bottomAppBarColor,
    borderRadius: BorderRadius.circular(15.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        spreadRadius: 2,
        blurRadius: 5,
        offset: Offset(0, 3),
      ),
    ],
  );

  static final TextStyle dialogTitleTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.iconColor,
  );

  static final TextStyle dialogContentTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
  );

  static final InputDecoration inputDecoration = InputDecoration(
    labelStyle: TextStyle(color: Colors.white),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.iconColor),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
    ),
  );

  static final Color dialogBackgroundColor = AppColors.appBarColor;

  static final ButtonStyle cancelButtonStyle = TextButton.styleFrom(
    foregroundColor: AppColors.iconColorWarning,
  );

  static final ButtonStyle deleteButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: AppColors.iconColorWarning, // Warna merah untuk kesalahan
  );

  static final ButtonStyle addButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: AppColors.iconColor,
  );

  static TextStyle get captionTextStyle {
    return TextStyle(
      fontSize: 12,
      color: AppColors.captionColor,
      fontWeight: FontWeight.normal,
    );
  }

  static TextStyle get titleCardPrimaryTextStyle {
    return TextStyle(
      fontSize: 24,
      color: AppColors.iconColor,
      fontWeight: FontWeight.bold,
    );
  }

  static final TextStyle titleTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static final TextStyle titleTextIconStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.iconColor,
  );

  static final TextStyle drawerHeaderTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.iconColor,
  );

  static final TextStyle drawerItemTextStyle = TextStyle(
    fontSize: 18,
    color: AppColors.textColor,
  );

  static final TextStyle bottomNavTextStyle = TextStyle(
    fontSize: 9,
    color: AppColors.unselectedItemColor,
  );

  static final TextStyle buttonTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textColor,
  );

  static final TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
    color: AppColors.textColor,
  );

  static final TextStyle headingTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static final TextStyle errorTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.redAccent, // Warna merah untuk teks error
    fontWeight: FontWeight.bold,
  );

  static final TextStyle emptyDataTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.grey, // Warna abu-abu untuk teks data kosong
    fontStyle: FontStyle.italic,
  );
}

// Button Decoration
final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
  foregroundColor: AppColors.textColor,
  backgroundColor: AppColors.buttonColor,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15.0),
  ),
  elevation: 5.0,
  textStyle: AppStyles.buttonTextStyle,
);

// AppBar Decoration
final AppBarTheme appBarTheme = AppBarTheme(
  color: AppColors.appBarColor,
  iconTheme: IconThemeData(color: AppColors.iconColor),
  titleTextStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  ),
);

// Drawer Style
final BoxDecoration drawerDecoration = BoxDecoration(
  color: AppColors.drawerHeaderColor,
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      spreadRadius: 2,
      blurRadius: 5,
      offset: Offset(0, 3),
    ),
  ],
);

// Bottom Navigation Bar Style
final BottomNavigationBarThemeData bottomNavBarTheme =
    BottomNavigationBarThemeData(
  selectedItemColor: AppColors.selectedItemColor,
  unselectedItemColor: AppColors.unselectedItemColor,
  backgroundColor: AppColors.bottomAppBarColor,
);
