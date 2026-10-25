// ábra- és táblázatcímek: félkövér "1. táblázat." + dőlt cím, balra igazítva
#show figure.caption: it => context block(width: 100%, align(left,
  strong(it.counter.display(it.numbering) + [. ] + it.supplement + [.])
    + [ ] + emph(it.body)))
