open import Data.Bool using (Bool; true; false; _∧_)
import Relation.Binary.PropositionalEquality as Eq
open Eq using (_≡_; refl; sym; subst)
open Eq.≡-Reasoning using (begin_; _≡⟨⟩_; _≡⟨_⟩_; _∎)
open import Data.Unit using (⊤; tt)
open import Data.Nat using (ℕ; zero; suc; _≤_; _≥_; _>_)
open import Data.Product using (_×_; _,_; proj₁; proj₂; Σ-syntax; ∃; ∃-syntax)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.List using (List; []; [_]; _∷_; _∷ʳ_; _++_)
open import Data.List.Reverse using (Reverse; reverseView)
open import Function using (_$_)

module SnapshotConsistency
  (Addr : Set) (_≟_ : Addr → Addr → Bool) (_≤?MAXADDR : Addr → Bool) (_≤?MAXWCNT : ℕ → Bool)
  (Data : Set) (defaultData : Data)
  where

infixl 20 _•_
infixl 20 _⊙_
infixl 20 _++RTC_
infixl 20 _<≐>_

variable
  addr : Addr
  dat  : Data

_≐_ : {A B : Set} → (A → B) → (A → B) → Set
s ≐ t = ∀ a → s a ≡ t a

sym-≐ : {A B : Set} {s t : A → B} → s ≐ t → t ≐ s
sym-≐ eq = λ{x → sym (eq x)}

_<≐>_ : {A B : Set} {s t u : A → B} → s ≐ t → t ≐ u → s ≐ u
_<≐>_ {A} {B} {s} {t} {u} e q = λ{x → begin s x ≡⟨ e x ⟩ t x ≡⟨ q x ⟩ u x ∎}

data SnocList (A : Set) : Set where
  []  : SnocList A
  _•_ : (as : SnocList A) → (a : A) → SnocList A

_⊙_ : {A : Set} → SnocList A → SnocList A → SnocList A
xs ⊙ []       = xs
xs ⊙ (ys • y) = (xs ⊙ ys) • y

data All {A : Set} (P : A → Set) : SnocList A → Set where
  []  : All P []
  _∷_ : ∀ {xs : SnocList A} {x : A} → All P xs → P x → All P (xs • x)

_++All_ : {A : Set} {P : A → Set} {xs ys : SnocList A} → All P xs → All P ys → All P (xs ⊙ ys)
all₁ ++All [] = all₁
all₁ ++All (all₂ ∷ x) = all₁ ++All all₂ ∷ x

mapAll : {A : Set} {P Q : A → Set} {xs : SnocList A}
       → ({x : A} → P x → Q x) → All P xs → All Q xs
mapAll pq []        = []
mapAll pq (all ∷ x) = (mapAll pq all) ∷ (pq x)

data Action : Set where
  w[_↦_]  : (addr : Addr) (dat : Data) → Action
  f       :                              Action
  r       :                              Action
  wᶜ[_↦_] : (addr : Addr) (dat : Data) → Action
  fᶜ      :                              Action
  rᶜ      :                              Action
  cp      :                              Action
  er      :                              Action
  cpᶜ     :                              Action
  erᶜ     :                              Action

variable
  ac : Action

data Regular : Action → Set where
  w  : Regular w[ addr ↦ dat ]
  cp : Regular cp
  er : Regular er

data Write : Action → Set where
  w  : Write w[ addr ↦ dat ]

data Snapshot : Action → Set where
  f : Snapshot f

data RecoveryCrash : Action → Set where
  rᶜ : RecoveryCrash rᶜ

data RegularSuccess : Action → Set where
  w : RegularSuccess w[ addr ↦ dat ]
  f : RegularSuccess f

data Regular×Snapshot : Action → Set where
  w  : Regular×Snapshot w[ addr ↦ dat ]
  cp : Regular×Snapshot cp
  er : Regular×Snapshot er
  f  : Regular×Snapshot f

data Regular×SnapshotCrash : Action → Set where
  wᶜ  : Regular×SnapshotCrash wᶜ[ addr ↦ dat ]
  fᶜ  : Regular×SnapshotCrash fᶜ
  cpᶜ : Regular×SnapshotCrash cpᶜ
  erᶜ : Regular×SnapshotCrash erᶜ

Trace = SnocList Action

variable
  ef  : Trace
  ef₁ : Trace
  ef₂ : Trace
  ef₃ : Trace
  frag     : Trace
  frag-w   : Trace
  frag-rᶜ  : Trace
  flist    : SnocList Action
  flist-w  : SnocList Action
  flist-rᶜ : SnocList Action

--Reflexive Transitive Closure
data RTC {A S : Set} (R : S → A → S → Set) : S → SnocList A → S → Set where
  ∅   : ∀ {s : S} → RTC R s [] s
  _•_ : ∀ {s t u : S} {acs : SnocList A} {ac : A}
      → RTC R s acs t → R t ac u → RTC R s (acs • ac) u

_++RTC_ : {A S : Set} {R : S → A → S → Set} {s t u : S} {ef₁ ef₂ : SnocList A}
        → RTC R s ef₁ t → RTC R t ef₂ u → RTC R s (ef₁ ⊙ ef₂) u
tc-s-t ++RTC ∅             = tc-s-t
tc-s-t ++RTC (tc-t-u • rr) = (tc-s-t ++RTC tc-t-u) • rr

splitRTC : {A S : Set} {R : S → A → S → Set} {s s' : S} → (splitOn : SnocList A) → {rest : SnocList A}
         → ( fr : RTC R s (splitOn ⊙ rest) s') → Σ[ s'' ∈ S ] Σ[ fr₁ ∈ RTC R s splitOn s'' ] Σ[ fr₂ ∈ RTC R s'' rest s' ] (fr ≡ (fr₁ ++RTC fr₂))
splitRTC ef₁ {rest = []}                t = (_ , t , ∅ , refl)
splitRTC ef₁ {rest = (ef₂ • ac)} (t • rr) with splitRTC ef₁ t
...                                       | s'' , t₁ , t₂ , refl = s'' , t₁ , t₂ • rr , refl

data OneRecovery : Trace → Set where
  wᶜ     : {tr₁ tr₂ tr₃ : Trace} → All Regular×Snapshot tr₁ → All Regular tr₂ → All RecoveryCrash tr₃
         → OneRecovery (tr₁ ⊙ ([] • f ⊙ tr₂) ⊙ ([] • wᶜ[ addr ↦ dat ] ⊙ tr₃ • r))
  fᶜ     : {tr₁ tr₂ tr₃ : Trace} → All Regular×Snapshot tr₁ → All Regular tr₂ → All RecoveryCrash tr₃
         → OneRecovery (tr₁ ⊙ ([] • f ⊙ tr₂) ⊙ ([] • fᶜ ⊙ tr₃ • r))
  wᶜ-nof : {tr₂ tr₃ : Trace} → All Regular tr₂ → All RecoveryCrash tr₃
         → OneRecovery (tr₂ ⊙ ([] • wᶜ[ addr ↦ dat ] ⊙ tr₃ • r))
  fᶜ-nof : {tr₂ tr₃ : Trace} → All Regular tr₂ → All RecoveryCrash tr₃
         → OneRecovery (tr₂ ⊙ ([] • fᶜ ⊙ tr₃ • r))

data MultiRecovery : Trace → Set where
  init : {tr : Trace} → All RecoveryCrash tr → MultiRecovery (tr • r)
  one  : {tr₁ tr₂ : Trace} → MultiRecovery tr₁ → OneRecovery tr₂ → MultiRecovery (tr₁ ⊙ tr₂)

data 1RFrags {S : Set} {R : S → Action → S → Set} : {s s' : S} {tr : Trace} → OneRecovery tr → RTC R s tr s' → Set where
  wᶜ     : {tr₁ tr₂ tr₃ : Trace} {all₁ : All Regular×Snapshot tr₁} {all₂ : All Regular tr₂} {all₃ : All RecoveryCrash tr₃}
         → {s₁ s₂ s₃ s₄ : S} (fr₁ : RTC R s₁ tr₁ s₂) (fr₂ : RTC R s₂ ([] • f ⊙ tr₂) s₃) (fr₃ : RTC R s₃ ([] • wᶜ[ addr ↦ dat ] ⊙ tr₃ • r) s₄)
         → 1RFrags (wᶜ all₁ all₂ all₃) (fr₁ ++RTC fr₂ ++RTC fr₃)
  fᶜ     : {tr₁ tr₂ tr₃ : Trace} {all₁ : All Regular×Snapshot tr₁} {all₂ : All Regular tr₂} {all₃ : All RecoveryCrash tr₃}
         → {s₁ s₂ s₃ s₄ : S} (fr₁ : RTC R s₁ tr₁ s₂) (fr₂ : RTC R s₂ ([] • f ⊙ tr₂) s₃) (fr₃ : RTC R s₃ ([] • fᶜ ⊙ tr₃ • r) s₄)
         → 1RFrags (fᶜ all₁ all₂ all₃) (fr₁ ++RTC fr₂ ++RTC fr₃)
  wᶜ-nof : {tr₂ tr₃ : Trace} {all₂ : All Regular tr₂} {all₃ : All RecoveryCrash tr₃}
         → {s₂ s₃ s₄ : S} (fr₂ : RTC R s₂ tr₂ s₃) (fr₃ : RTC R s₃ ([] • wᶜ[ addr ↦ dat ] ⊙ tr₃ • r) s₄)
         → 1RFrags (wᶜ-nof all₂ all₃) (fr₂ ++RTC fr₃)
  fᶜ-nof : {tr₂ tr₃ : Trace} {all₂ : All Regular tr₂} {all₃ : All RecoveryCrash tr₃}
         → {s₂ s₃ s₄ : S} (fr₂ : RTC R s₂ tr₂ s₃) (fr₃ : RTC R s₃ ([] • fᶜ ⊙ tr₃ • r) s₄)
         → 1RFrags (fᶜ-nof all₂ all₃) (fr₂ ++RTC fr₃)

view1R : {tr : Trace} (1r : OneRecovery tr) {S : Set} {R : S → Action → S → Set} {s s' : S} (fr : RTC R s tr s') → 1RFrags 1r fr
view1R (wᶜ {tr₁ = tr₁} {tr₂ = tr₂} {tr₃ = tr₃} all₁ all₂ all₃) {s = s₁} {s' = s₄} fr
  with splitRTC (tr₁ ⊙ ([] • f ⊙ tr₂)) {rest = [] • wᶜ[ _ ↦ _ ] ⊙ tr₃ • r} fr
...  | s₃ , fr-l , fr₃ , refl with splitRTC tr₁ {rest = [] • f ⊙ tr₂} fr-l
...  | s₂ , fr₁  , fr₂ , refl = wᶜ fr₁ fr₂ fr₃
view1R (fᶜ {tr₁ = tr₁} {tr₂ = tr₂} {tr₃ = tr₃} all₁ all₂ all₃) {s = s₁} {s' = s₄} fr
  with splitRTC (tr₁ ⊙ ([] • f ⊙ tr₂)) {rest = [] • fᶜ ⊙ tr₃ • r} fr
...  | s₃ , fr-l , fr₃ , refl with splitRTC tr₁ {rest = [] • f ⊙ tr₂} fr-l
...  | s₂ , fr₁  , fr₂ , refl = fᶜ fr₁ fr₂ fr₃
view1R (wᶜ-nof {tr₂ = tr₂} {tr₃ = tr₃} all₂ all₃) fr with splitRTC tr₂ fr
...  | _ , fr₁ , fr₂ , refl = wᶜ-nof fr₁ fr₂
view1R (fᶜ-nof {tr₂ = tr₂} {tr₃ = tr₃} all₂ all₃) fr with splitRTC tr₂ fr
...  | _ , fr₁ , fr₂ , refl = fᶜ-nof fr₁ fr₂

data MRFrags {S : Set} {R : S → Action → S → Set} : {s s' : S} {tr : Trace} → MultiRecovery tr → RTC R s tr s' → Set where
  init : {tr : Trace} {all : All RecoveryCrash tr} {s s' : S} (fr : RTC R s (tr • r) s') → MRFrags (init all) fr
  one  : {tr₁ : Trace} {mr : MultiRecovery tr₁} {s₁ s₂ : S} {fr₁ : RTC R s₁ tr₁ s₂} → MRFrags mr fr₁
       → {tr₂ : Trace} {1r : OneRecovery   tr₂} {s₃    : S} (fr₂ : RTC R s₂ tr₂ s₃) → 1RFrags 1r fr₂ → MRFrags (one mr 1r) (fr₁ ++RTC fr₂)

viewMR : {tr : Trace} (mr : MultiRecovery tr) {S : Set} {R : S → Action → S → Set} {s s' : S} (fr : RTC R s tr s') → MRFrags mr fr
viewMR (init all) fr = init fr
viewMR (one  {tr₁ = tr₁} mr all) fr with splitRTC tr₁ fr
...  | _ , fr-l , fr-r , refl = one  (viewMR mr fr-l) fr-r (view1R all fr-r)

lastr : {S : Set} {s s' : S} {R : S → Action → S → Set} {tr : Trace} (mr : MultiRecovery tr)
      → (fr : RTC R s tr s') → (frs : MRFrags mr fr) → Σ[ s'' ∈ S ] (R s'' r s')
lastr .(init _) .fr (init fr) with fr
... | _ • x =  _ , x
lastr ._ ._ (one _ ._ (wᶜ _ _ (fr₃ • x))) = _ , x
lastr ._ ._ (one _ ._ (fᶜ _ _ (fr₃ • x))) = _ , x
lastr ._ ._ (one _ ._ (wᶜ-nof _ (fr₃ • x))) = _ , x
lastr ._ ._ (one _ ._ (fᶜ-nof _ (fr₃ • x))) = _ , x

SnapshotConsistency : {S : Set} {s s' : S} {R : S → Action → S → Set} (ER : S → S → Set)
                      {tr : Trace} → (1r : OneRecovery tr) → (fr : RTC R s tr s') → 1RFrags 1r fr → Set
SnapshotConsistency ER ._ ._ (wᶜ     {s₂ = s₂} {s₄ = s₄} _ _ _) = ER s₂ s₄
SnapshotConsistency ER ._ ._ (fᶜ     {s₂ = s₂} {s₃} {s₄} _ _ _) = ER s₃ s₄ ⊎ ER s₂ s₄
SnapshotConsistency ER ._ ._ (wᶜ-nof {s₂ = s₂} {s₄ = s₄}   _ _) = ER s₂ s₄
SnapshotConsistency ER ._ ._ (fᶜ-nof {s₂ = s₂} {s₃} {s₄}   _ _) = ER s₃ s₄ ⊎ ER s₂ s₄

module Spec where

  record State : Set where
    field
      volatile : Addr → Data
      stable   : Addr → Data
      w-count  : ℕ

  Init : State → Set
  Init s = (addr : Addr) → (State.stable s addr ≡ defaultData)

  variable
    t  : State
    t' : State

  update : (Addr → Data) → ℕ → Addr → Data → (Addr → Data)
  update s wcnt addr dat i with (addr ≤?MAXADDR) ∧ (wcnt ≤?MAXWCNT)
  update s wcnt addr dat i | false = s i
  update s wcnt addr dat i | true with addr ≟ i
  update s wcnt addr dat i | true | true  = dat
  update s wcnt addr dat i | true | false = s i

  data Step (s s' : State) : Action → Set where
    w   : update (State.volatile s) (State.w-count s) addr dat ≐ State.volatile s'
        → State.stable s ≐ State.stable s'
        → suc (State.w-count s) ≡ State.w-count s'
        → Step s s' w[ addr ↦ dat ]
    f   : State.volatile s ≐ State.volatile s'
        → State.volatile s ≐ State.stable s'
        → State.w-count s' ≡ zero
        → Step s s' f
    r   : State.stable s ≐ State.volatile s'
        → State.stable s ≐ State.stable s'
        → State.w-count s' ≡ zero
        → Step s s' r
    wᶜ  : State.stable s ≐ State.stable s'
        → Step s s' (wᶜ[ addr ↦ dat ])
    fᶜ  : State.volatile s ≐ State.stable s' ⊎ State.stable s ≐ State.stable s'
        → Step s s' fᶜ
    rᶜ  : State.stable s ≐ State.stable s'
        → Step s s' rᶜ
    cp  : State.volatile s ≐ State.volatile s'
        → State.stable s ≐ State.stable s'
        → State.w-count s ≡ State.w-count s'
        → Step s s' cp
    er  : State.volatile s ≐ State.volatile s'
        → State.stable s ≐ State.stable s'
        → State.w-count s ≡ State.w-count s'
        → Step s s' er
    cpᶜ : State.stable s ≐ State.stable s' → Step s s' cpᶜ
    erᶜ : State.stable s ≐ State.stable s' → Step s s' erᶜ

  _⟦_⟧▸_ : State → Action → State → Set
  s ⟦ ac ⟧▸ s' = Step s s' ac

  _⟦_⟧*▸_ = RTC  _⟦_⟧▸_

  record StbP (ac : Action) : Set where --Stability Reserving Actions
    field
      preserve : {s s' : State} → s ⟦ ac ⟧▸ s' → (State.stable s ≐ State.stable s')

  instance
    stb-r   : StbP r
    stb-r   = record { preserve = λ{(r _ ss _) → ss} }
    stb-w   : StbP w[ addr ↦ dat ]
    stb-w   = record { preserve = λ{(w _ ss _ ) → ss} }
    stb-wᶜ  : StbP wᶜ[ addr ↦ dat ]
    stb-wᶜ  = record { preserve = λ{(wᶜ ss) → ss} }
    stb-rᶜ  : StbP rᶜ
    stb-rᶜ  = record { preserve = λ{(rᶜ ss) → ss} }
    stb-cp  : StbP cp
    stb-cp  = record { preserve = λ{(cp _ ss _) → ss}}
    stb-er  : StbP er
    stb-er  = record { preserve = λ{(er _ ss _) → ss}}
    stb-cpᶜ : StbP cpᶜ
    stb-cpᶜ = record { preserve = λ{(cpᶜ ss) → ss}}
    stb-erᶜ : StbP erᶜ
    stb-erᶜ = record { preserve = λ{(erᶜ ss) → ss}}

  idemₛ : {tr : Trace} → All StbP tr
        → ∀ {s s' : State} → s ⟦ tr ⟧*▸ s'
        → State.stable s ≐ State.stable s'
  idemₛ [] ∅ = λ{_ → refl}
  idemₛ (all ∷ x) (s2s'' • s''2s') =
    idemₛ all s2s'' <≐> StbP.preserve x s''2s'

  r→rs : Regular ac → Regular×Snapshot ac
  r→rs w = w
  r→rs cp = cp
  r→rs er = er

  n→sp : Regular ac → StbP ac
  n→sp w  = stb-w
  n→sp cp = stb-cp
  n→sp er = stb-er

  rᶜ→sp : RecoveryCrash ac → StbP ac
  rᶜ→sp rᶜ = stb-rᶜ

  SpecSC-wᶜ : ∀ {s₂ s₃ s₄ : State} {tr-w tr-rᶜ}
             → {{_ : All Regular tr-w}} {{_ : All RecoveryCrash tr-rᶜ}}
             → s₂ ⟦ [] • f ⊙ tr-w ⟧*▸ s₃ → s₃ ⟦ [] • wᶜ[ addr ↦ dat ] ⊙ tr-rᶜ • r ⟧*▸ s₄
             → State.volatile s₂ ≐ State.volatile s₄
  SpecSC-wᶜ {{ all₂ }} {{ all₃ }} s₂▸s₃ (s₃▹ • r sv _ _)
        with splitRTC ([] • f) s₂▸s₃ | splitRTC ([] • wᶜ[ _ ↦ _ ]) s₃▹
  ...      | s₂' , ∅ • (f vv vs _) , s₂'▸s₃ , _ | s₃' , ∅ • (wᶜ ss) , s₃'▸s₄▹ , _ =
               vs <≐> idemₛ (mapAll n→sp  all₂) s₂'▸s₃  <≐>
               ss <≐> idemₛ (mapAll rᶜ→sp all₃) s₃'▸s₄▹ <≐> sv

  SpecSC-wᶜ-nof : ∀ {s₁ s₂ s₃ s₄ : State} {tr-w tr-rᶜ}
                → {{_ : All Regular tr-w}} {{_ : All RecoveryCrash tr-rᶜ}}
                → s₁ ⟦ r ⟧▸ s₂ → s₂ ⟦ tr-w ⟧*▸ s₃ → s₃ ⟦ [] • wᶜ[ addr ↦ dat ] ⊙ tr-rᶜ • r ⟧*▸ s₄
                → State.volatile s₂ ≐ State.volatile s₄
  SpecSC-wᶜ-nof {{ all₂ }} {{ all₃ }} (r sv' ss' _) s₂▸s₃ (s₃▹ • r sv _ _)
           with splitRTC ([] • wᶜ[ _ ↦ _ ]) s₃▹
  ...         | s₃' , ∅ • (wᶜ ss) , s₃'▸s₄▹ , _ =
                  sym-≐ sv' <≐> ss' <≐> idemₛ (mapAll n→sp  all₂) s₂▸s₃  <≐>
                  ss <≐> idemₛ (mapAll rᶜ→sp all₃) s₃'▸s₄▹ <≐> sv

  SpecSC-fᶜ : ∀ {s₂ s₃ s : State} {tr-w tr-rᶜ}
             → {{_ : All Regular tr-w}} {{_ : All RecoveryCrash tr-rᶜ}}
             → s₂ ⟦ ([] • f) ⊙ tr-w ⟧*▸ s₃ → s₃ ⟦ ([] • fᶜ) ⊙ tr-rᶜ • r ⟧*▸ s
             → State.volatile s₃ ≐ State.volatile s ⊎ State.volatile s₂ ≐ State.volatile s
  SpecSC-fᶜ {{all₁}} {{all₂}} s₂▸s₃ (s₃▸s • r sv ss _)
        with splitRTC ([] • f) s₂▸s₃ | splitRTC ([] • fᶜ) s₃▸s
  ...      | _ , ∅ • f vv vs _ , ▸s₃ , _ | s₃' , ∅ • fᶜ (inj₁ vsᶜ) , s₃'▸s , _ =
               inj₁ $ vsᶜ <≐> idemₛ (mapAll rᶜ→sp all₂) s₃'▸s <≐> sv
  ...      | _ , ∅ • f vv vs _ , ▸s₃ , _ | s₃' , ∅ • fᶜ (inj₂ ssᶜ) , s₃'▸s , _ =
               inj₂ $ vs <≐>
               idemₛ (mapAll n→sp all₁) ▸s₃ <≐> ssᶜ <≐>
               idemₛ (mapAll rᶜ→sp all₂) s₃'▸s <≐> sv

  SpecSC-fᶜ-nof : ∀ {s₁ s₂ s₃ s₄ : State} {tr-w tr-rᶜ}
                → {{_ : All Regular tr-w}} {{_ : All RecoveryCrash tr-rᶜ}}
                → s₁ ⟦ r ⟧▸ s₂ → s₂ ⟦ tr-w ⟧*▸ s₃ → s₃ ⟦ [] • fᶜ ⊙ tr-rᶜ • r ⟧*▸ s₄
                → State.volatile s₃ ≐ State.volatile s₄ ⊎ State.volatile s₂ ≐ State.volatile s₄
  SpecSC-fᶜ-nof {{ all₂ }} {{ all₃ }} (r sv' ss' _) s₂▸s₃ (s₃▹ • r sv _ _)
           with splitRTC ([] • fᶜ) s₃▹
  ...         | s₃' , ∅ • fᶜ (inj₁ vsᶜ) , s₃'▸s , _ = inj₁ $ vsᶜ <≐> idemₛ (mapAll rᶜ→sp all₃) s₃'▸s <≐> sv
  ...         | s₃' , ∅ • fᶜ (inj₂ ssᶜ) , s₃'▸s , _ = inj₂ $ sym-≐ sv' <≐> ss' <≐>
                                                             idemₛ (mapAll n→sp  all₂) s₂▸s₃ <≐> ssᶜ <≐>
                                                             idemₛ (mapAll rᶜ→sp all₃) s₃'▸s <≐> sv

  SC : {t₀ t t' : State} {tr₀ tr : Trace} → (mr : MultiRecovery tr₀) → (1r : OneRecovery tr)
     → Init t₀ → (fr₀ : t₀ ⟦ tr₀ ⟧*▸ t) → MRFrags mr fr₀ → (fr : t ⟦ tr ⟧*▸ t') → (frs : 1RFrags 1r fr)
     → SnapshotConsistency (λ t t' → State.volatile t ≐ State.volatile t') 1r fr frs
  SC mr _ init-t₀ fr₀ frs₀ ._ (wᶜ {all₂ = all₂} {all₃} fr₁ fr₂ fr₃) = SpecSC-wᶜ {{all₂}} {{all₃}} fr₂ fr₃
  SC mr _ init-t₀ fr₀ frs₀ ._ (fᶜ {all₂ = all₂} {all₃} fr₁ fr₂ fr₃) = SpecSC-fᶜ {{all₂}} {{all₃}} fr₂ fr₃
  SC mr _ init-t₀ fr₀ frs₀ ._ (wᶜ-nof {all₂ = all₂} {all₃} fr₂ fr₃) = SpecSC-wᶜ-nof {{all₂}} {{all₃}} (proj₂ (lastr mr fr₀ frs₀)) fr₂ fr₃
  SC mr _ init-t₀ fr₀ frs₀ ._ (fᶜ-nof {all₂ = all₂} {all₃} fr₂ fr₃) = SpecSC-fᶜ-nof {{all₂}} {{all₃}} (proj₂ (lastr mr fr₀ frs₀)) fr₂ fr₃

open Spec hiding (SC)

module Prog
  (runSpec : (t : State) (ac : Action) → ∃[ t' ] (t ⟦ ac ⟧▸ t'))
  (RawStateᴾ : Set) (_⟦_⟧ᴿ▸_ : RawStateᴾ → Action → RawStateᴾ → Set)
  (RI CI : RawStateᴾ → Set)
  (AR CR : RawStateᴾ → State → Set)
  (RIRI : {s s' : RawStateᴾ} {ac : Action} → Regular×Snapshot ac → s ⟦ ac ⟧ᴿ▸ s' → RI s → RI s')
  (ARAR : {s s' : RawStateᴾ} {t t' : State} {ac : Action} → Regular×Snapshot ac
        → s ⟦ ac ⟧ᴿ▸ s' → t ⟦ ac ⟧▸ t' → RI s × AR s t → AR s' t')
  (RICI : {s s' : RawStateᴾ} {ac : Action} → Regular×SnapshotCrash ac → s ⟦ ac ⟧ᴿ▸ s' → RI s → CI s')
  (ARCR : {s s' : RawStateᴾ} {t t' : State} {ac : Action} → Regular×SnapshotCrash ac
        → s ⟦ ac ⟧ᴿ▸ s' → t ⟦ ac ⟧▸ t' → RI s × AR s t → CR s' t')
  (CIRI : {s s' : RawStateᴾ} → s ⟦ r ⟧ᴿ▸ s' → CI s → RI s')
  (CRAR : {s s' : RawStateᴾ} {t t' : State} → s ⟦ r ⟧ᴿ▸ s' → t ⟦ r ⟧▸ t' → CI s × CR s t → AR s' t')
  (CICI : {s s' : RawStateᴾ} → s ⟦ rᶜ ⟧ᴿ▸ s' → CI s → CI s')
  (CRCR : {s s' : RawStateᴾ} {t t' : State} → s ⟦ rᶜ ⟧ᴿ▸ s' → t ⟦ rᶜ ⟧▸ t' → CI s × CR s t → CR s' t')
  (read : RawStateᴾ → Addr → Data)
  (AR⇒ObsEquiv : {s : RawStateᴾ} {t : State} → RI s × AR s t → read s ≐ State.volatile t)
  (Initᴿ : RawStateᴾ → Set)
  (initᴿ-CI : (s : RawStateᴾ) → Initᴿ s → CI s)
  (initᴿ-CR : (s : RawStateᴾ) → Initᴿ s → (t : State) → Init t → CR s t)
  (t-init : Σ[ t ∈ State ] Init t)
  where

  variable
    rs    : RawStateᴾ
    rs₁   : RawStateᴾ
    rinv  : RI rs
    cinv  : CI rs
    rs'   : RawStateᴾ
    rs''  : RawStateᴾ
    rs''' : RawStateᴾ
    rinv' : RI rs'
    cinv' : CI rs'

  _⟦_⟧ᴿ*▸_ = RTC _⟦_⟧ᴿ▸_

  data Inv (rs : RawStateᴾ) : Set where
    normal : RI rs → Inv rs
    crash  : CI rs → Inv rs

  Stateᴾ : Set
  Stateᴾ = Σ[ rs ∈ RawStateᴾ ] Inv rs

  data Initᴾ : Stateᴾ → Set where
    init : Initᴿ rs → Initᴾ (rs , crash cinv)

  variable
    s    : Stateᴾ
    s'   : Stateᴾ
    s''  : Stateᴾ
    s''' : Stateᴾ

  data _⟦_⟧ᴾ▸_ : Stateᴾ → Action → Stateᴾ → Set where
    w   : rs ⟦ w[ addr ↦ dat ] ⟧ᴿ▸ rs'  → (rs , normal rinv) ⟦ w[ addr ↦ dat ] ⟧ᴾ▸ (rs' , normal rinv')
    f   : rs ⟦ f   ⟧ᴿ▸ rs'              → (rs , normal rinv) ⟦ f  ⟧ᴾ▸ (rs' , normal rinv')
    wᶜ  : rs ⟦ wᶜ[ addr ↦ dat ] ⟧ᴿ▸ rs' → (rs , normal rinv) ⟦ wᶜ[ addr ↦ dat ] ⟧ᴾ▸ (rs' , crash  cinv')
    fᶜ  : rs ⟦ fᶜ  ⟧ᴿ▸ rs'              → (rs , normal rinv) ⟦ fᶜ ⟧ᴾ▸ (rs' , crash  cinv')
    rᶜ  : rs ⟦ rᶜ  ⟧ᴿ▸ rs'              → (rs , crash  cinv) ⟦ rᶜ ⟧ᴾ▸ (rs' , crash  cinv')
    r   : rs ⟦ r   ⟧ᴿ▸ rs'              → (rs , crash  cinv) ⟦ r  ⟧ᴾ▸ (rs' , normal rinv')
    cp  : rs ⟦ cp  ⟧ᴿ▸ rs'              → (rs , normal rinv) ⟦ cp ⟧ᴾ▸ (rs' , normal rinv')
    er  : rs ⟦ er  ⟧ᴿ▸ rs'              → (rs , normal rinv) ⟦ er ⟧ᴾ▸ (rs' , normal rinv')
    cpᶜ : rs ⟦ cpᶜ ⟧ᴿ▸ rs'              → (rs , normal rinv) ⟦ cpᶜ ⟧ᴾ▸ (rs' , crash cinv')
    erᶜ : rs ⟦ erᶜ ⟧ᴿ▸ rs'              → (rs , normal rinv) ⟦ erᶜ ⟧ᴾ▸ (rs' , crash cinv')

  _⟦_⟧ᴾ*▸_ = RTC  _⟦_⟧ᴾ▸_

  lift-n×s : {tr : Trace} {{_ : All Regular×Snapshot tr}} → rs ⟦ tr ⟧ᴿ*▸ rs' →
             ∃[ rinv' ] ((rs , normal rinv) ⟦ tr ⟧ᴾ*▸ (rs' , normal rinv'))
  lift-n×s ∅ = _ , ∅
  lift-n×s {{all ∷ w}} (rs*▸rs'' • rs''▸rs') =
    let (rinv'' , s*▸s'') = lift-n×s {{all}} rs*▸rs''
    in  RIRI w rs''▸rs' rinv'' , s*▸s'' • w rs''▸rs'
  lift-n×s {{all ∷ f}} (rs*▸rs'' • rs''▸rs') =
    let (rinv'' , s*▸s'') = lift-n×s {{all}} rs*▸rs''
    in  RIRI f rs''▸rs' rinv'' , s*▸s'' • f rs''▸rs'
  lift-n×s {{all ∷ cp}} (rs*▸rs'' • rs''▸rs') =
    let (rinv'' , s*▸s'') = lift-n×s {{all}} rs*▸rs''
    in  RIRI cp rs''▸rs' rinv'' , s*▸s'' • cp rs''▸rs'
  lift-n×s {{all ∷ er}} (rs*▸rs'' • rs''▸rs') =
    let (rinv'' , s*▸s'') = lift-n×s {{all}} rs*▸rs''
    in  RIRI er rs''▸rs' rinv'' , s*▸s'' • er rs''▸rs'

  lift-n : {tr : Trace} {{_ : All Regular tr}} → rs ⟦ tr ⟧ᴿ*▸ rs'
         → ∃[ rinv' ] ((rs , normal rinv) ⟦ tr ⟧ᴾ*▸ (rs' , normal rinv'))
  lift-n {{all}} rs*▸rs' =
    lift-n×s {{(mapAll (λ{w → w; cp → cp; er → er}) all)}} rs*▸rs'

  lift-rᶜ : {tr : Trace} {{_ : All RecoveryCrash tr}} → rs ⟦ tr ⟧ᴿ*▸ rs' →
            ∃[ cinv' ] ((rs , crash cinv) ⟦ tr ⟧ᴾ*▸ (rs' , crash cinv'))
  lift-rᶜ ∅ = _ , ∅
  lift-rᶜ {{all ∷ rᶜ}} (rs*▸rs'' • rs''▸rs') =
    let (cinv'' , s*▸s'') = lift-rᶜ {{all}} rs*▸rs''
    in  CICI rs''▸rs' cinv'' , s*▸s'' • rᶜ rs''▸rs'

  lift-mr : {tr : Trace} (mr : MultiRecovery tr) (fr : rs ⟦ tr ⟧ᴿ*▸ rs') → MRFrags mr fr → Initᴿ rs
          → ∃[ cinv ] ∃[ rinv' ] let s = (rs , crash cinv) in (s ⟦ tr ⟧ᴾ*▸ (rs' , normal rinv')) × Initᴾ s
  lift-mr ._ ._ (init {all = all} fr) init-rs with fr
  ... | fr₀ • rr with lift-rᶜ {cinv = initᴿ-CI _ init-rs} {{all}} fr₀
  ... | cinv₀ , fr₀ᴾ = _ , CIRI rr cinv₀ , fr₀ᴾ • r rr , init init-rs
  lift-mr ._ ._ (one frs₀ fr frs) init-rs with lift-mr _ _ frs₀ init-rs
  lift-mr ._ ._ (one frs₀ ._ (wᶜ {tr₃ = tr₃} {all₁ = all₁} {all₂} {all₃} fr₁ fr₂ fr₃)) init-rs | cinv₀ , rinv₀ , fr₀ᴾ , init-s with splitRTC ([] • (wᶜ[ _ ↦ _ ])) {rest = (tr₃ • r)} fr₃
  ...   | rs'' , ∅ • s₃▸s₃' , s₃'▸r • r▸rs' , eq with lift-n×s {rinv = rinv₀} {{all₁}} fr₁
  ...   | rinv₁ , frP₁ with lift-n×s {rinv = rinv₁} {{ ([] ∷ f) ++All mapAll r→rs all₂ }} fr₂
  ...   | rinv₂ , frP₂ with RICI wᶜ s₃▸s₃' rinv₂
  ...   | cinv₂' with lift-rᶜ {cinv = cinv₂'} {{all₃}} s₃'▸r
  ...   | cinv₃ , frP₃ with CIRI r▸rs' cinv₃
  ...   | rinv₄  = cinv₀ , rinv₄ ,  fr₀ᴾ ++RTC (frP₁ ++RTC frP₂ ++RTC ((∅ • wᶜ s₃▸s₃') ++RTC (frP₃ • r r▸rs'))), init-s
  lift-mr ._ ._ (one frs₀ ._ (fᶜ {tr₃ = tr₃} {all₁ = all₁} {all₂} {all₃} fr₁ fr₂ fr₃)) init-rs | cinv₀ , rinv₀ , fr₀ᴾ , init-s with splitRTC ([] • fᶜ) {rest = (tr₃ • r)} fr₃
  ...   | rs'' , ∅ • s₃▸s₃' , s₃'▸r • r▸rs' , eq with lift-n×s {rinv = rinv₀} {{all₁}} fr₁
  ...   | rinv₁ , frP₁ with lift-n×s {rinv = rinv₁} {{ ([] ∷ f) ++All mapAll r→rs all₂ }} fr₂
  ...   | rinv₂ , frP₂ with RICI fᶜ s₃▸s₃' rinv₂
  ...   | cinv₂' with lift-rᶜ {cinv = cinv₂'} {{all₃}} s₃'▸r
  ...   | cinv₃ , frP₃ with CIRI r▸rs' cinv₃
  ...   | rinv₄  = cinv₀ , rinv₄ ,  fr₀ᴾ ++RTC (frP₁ ++RTC frP₂ ++RTC ((∅ • fᶜ s₃▸s₃') ++RTC (frP₃ • r r▸rs'))), init-s
  lift-mr ._ ._ (one frs₀ ._ (wᶜ-nof {tr₃ = tr₃} {all₂ = all₂} {all₃} fr₂ fr₃)) init-rs | cinv₀ , rinv₀ , fr₀ᴾ , init-s with splitRTC ([] • wᶜ[ _ ↦ _ ]) {rest = (tr₃ • r)} fr₃
  ...   | rs'' , ∅ • s₃▸s₃' , s₃'▸r • r▸rs' , eq with lift-n×s {rinv = rinv₀} {{ mapAll r→rs all₂ }} fr₂
  ...   | rinv₂ , frP₂ with RICI wᶜ s₃▸s₃' rinv₂
  ...   | cinv₂' with lift-rᶜ {cinv = cinv₂'} {{all₃}} s₃'▸r
  ...   | cinv₃ , frP₃ with CIRI r▸rs' cinv₃
  ...   | rinv₄  = cinv₀ , rinv₄ ,  fr₀ᴾ ++RTC (frP₂ ++RTC ((∅ • wᶜ s₃▸s₃') ++RTC (frP₃ • r r▸rs'))), init-s
  lift-mr ._ ._ (one frs₀ ._ (fᶜ-nof {tr₃ = tr₃} {all₂ = all₂} {all₃} fr₂ fr₃)) init-rs | cinv₀ , rinv₀ , fr₀ᴾ , init-s with splitRTC ([] • fᶜ) {rest = (tr₃ • r)} fr₃
  ...   | rs'' , ∅ • s₃▸s₃' , s₃'▸r • r▸rs' , eq with lift-n×s {rinv = rinv₀} {{ mapAll r→rs all₂ }} fr₂
  ...   | rinv₂ , frP₂ with RICI fᶜ s₃▸s₃' rinv₂
  ...   | cinv₂' with lift-rᶜ {cinv = cinv₂'} {{all₃}} s₃'▸r
  ...   | cinv₃ , frP₃ with CIRI r▸rs' cinv₃
  ...   | rinv₄  = cinv₀ , rinv₄ ,  fr₀ᴾ ++RTC (frP₂ ++RTC ((∅ • fᶜ s₃▸s₃') ++RTC (frP₃ • r r▸rs'))), init-s

  ObsEquiv : Stateᴾ → State → Set
  ObsEquiv (rs , _) t = read rs ≐ State.volatile t

  data SR : Stateᴾ → State → Set where
    ar : AR rs t → SR (rs , normal rinv) t
    cr : CR rs t → SR (rs , crash  cinv) t

  simSR : SR s t → s ⟦ ac ⟧ᴾ▸ s' → ∃[ t' ] (t ⟦ ac ⟧▸ t' × SR s' t')
  simSR {s , normal rinv} {t} (ar AR-rs-t) (w {addr = addr} {dat = dat} rs▸rs') =
    let (t' , t▸t') = runSpec t w[ addr ↦ dat ]
    in   t' , t▸t' , ar (ARAR w rs▸rs' t▸t' (rinv , AR-rs-t))
  simSR {s , normal rinv} {t} (ar AR-rs-t) (f rs▸rs')  =
    let (t' , t▸t') = runSpec t f
    in   t' , t▸t' , ar (ARAR f rs▸rs' t▸t' (rinv , AR-rs-t))
  simSR {s , normal rinv} {t} (ar AR-rs-t) (wᶜ {addr = addr} {dat = dat} rs▸rs') =
    let (t' , t▸t') = runSpec t wᶜ[ addr ↦ dat ]
    in   t' , t▸t' , cr (ARCR wᶜ rs▸rs' t▸t' (rinv , AR-rs-t))
  simSR {s , normal rinv} {t} (ar AR-rs-t) (fᶜ rs▸rs') =
    let (t' , t▸t') = runSpec t fᶜ
    in   t' , t▸t' , cr (ARCR fᶜ rs▸rs' t▸t' (rinv , AR-rs-t))
  simSR {s , crash  cinv} {t} (cr CR-rs-t) (rᶜ rs▸rs') =
    let (t' , t▸t') = runSpec t rᶜ
    in   t' , t▸t' , cr (CRCR    rs▸rs' t▸t' (cinv , CR-rs-t))
  simSR {s , crash  cinv} {t} (cr CR-rs-t) (r rs▸rs')  =
    let (t' , t▸t') = runSpec t r
    in   t' , t▸t' , ar (CRAR    rs▸rs' t▸t' (cinv , CR-rs-t))
  simSR {s , normal rinv} {t} (ar AR-rs-t) (cp rs▸rs')  =
    let (t' , t▸t') = runSpec t cp
    in   t' , t▸t' , ar (ARAR cp rs▸rs' t▸t' (rinv , AR-rs-t))
  simSR {s , normal rinv} {t} (ar AR-rs-t) (er rs▸rs')  =
    let (t' , t▸t') = runSpec t er
    in   t' , t▸t' , ar (ARAR er rs▸rs' t▸t' (rinv , AR-rs-t))
  simSR {s , normal rinv} {t} (ar AR-rs-t) (cpᶜ rs▸rs') =
    let (t' , t▸t') = runSpec t cpᶜ
    in   t' , t▸t' , cr (ARCR cpᶜ rs▸rs' t▸t' (rinv , AR-rs-t))
  simSR {s , normal rinv} {t} (ar AR-rs-t) (erᶜ rs▸rs') =
    let (t' , t▸t') = runSpec t erᶜ
    in   t' , t▸t' , cr (ARCR erᶜ rs▸rs' t▸t' (rinv , AR-rs-t))

  runSimSR : SR s t → s ⟦ ef ⟧ᴾ*▸ s' → ∃[ t' ] (t ⟦ ef ⟧*▸ t' × SR s' t')
  runSimSR SR-s-t ∅                 = _ , ∅ , SR-s-t
  runSimSR SR-s-t (s*▸s'' • s''▸s') =
    let (t'' , t*▸t'' , SR-s''-t'') = runSimSR SR-s-t s*▸s''
        (t'  , t''▸t' , SR-s'-t'  ) = simSR SR-s''-t'' s''▸s'
    in  _ , (t*▸t'' • t''▸t') , SR-s'-t'

  Conformant-all : {tr : Trace} {s s' : Stateᴾ} → s ⟦ tr ⟧ᴾ*▸ s' → {t t' : State} → t ⟦ tr ⟧*▸ t' → Set
  Conformant-all {s' = s'} ∅         {t' = t'} ∅         = ⊤
  Conformant-all {s' = s'} (frP • _) {t' = t'} (frS • _) = Conformant-all frP frS × ObsEquiv s' t'

  Conformant-1R : {tr : Trace} (1r : OneRecovery tr)
                 → {s s' : Stateᴾ} (frP : s ⟦ tr ⟧ᴾ*▸ s') → 1RFrags 1r frP
                 → {t t' : State } (frS : t ⟦ tr ⟧*▸  t') → 1RFrags 1r frS → Set
  Conformant-1R ._ {s' = s'} ._ (wᶜ frP₁ frP₂ frP₃) {t' = t'} ._ (wᶜ frS₁ frS₂ frS₃) = Conformant-all (frP₁ ++RTC frP₂) (frS₁ ++RTC frS₂) × ObsEquiv s' t'
  Conformant-1R ._ {s' = s'} ._ (fᶜ frP₁ frP₂ frP₃) {t' = t'} ._ (fᶜ frS₁ frS₂ frS₃) = Conformant-all (frP₁ ++RTC frP₂) (frS₁ ++RTC frS₂) × ObsEquiv s' t'
  Conformant-1R ._ {s' = s'} ._ (wᶜ-nof  frP₂ frP₃) {t' = t'} ._ (wᶜ-nof  frS₂ frS₃) = Conformant-all frP₂ frS₂ × ObsEquiv s' t'
  Conformant-1R ._ {s' = s'} ._ (fᶜ-nof  frP₂ frP₃) {t' = t'} ._ (fᶜ-nof  frS₂ frS₃) = Conformant-all frP₂ frS₂ × ObsEquiv s' t'

  Conformant-all-intermediate : {s₁ s₂ s₃ : Stateᴾ} {t₁ t₂ t₃ : State} {tr tr' : Trace}
                                 (frP : s₁ ⟦ tr ⟧ᴾ*▸ s₂) (frS : t₁ ⟦ tr ⟧*▸ t₂) (frP' : s₂ ⟦ tr' ⟧ᴾ*▸ s₃) (frS' : t₂ ⟦ tr' ⟧*▸ t₃)
                               → Conformant-all (frP ++RTC frP') (frS ++RTC frS') → ObsEquiv s₁ t₁ → ObsEquiv s₂ t₂
  Conformant-all-intermediate ∅ ∅ _ _ conf oe = oe
  Conformant-all-intermediate (frP • sP) (frS • sS) ∅ ∅ conf oe = proj₂ conf
  Conformant-all-intermediate (frP • sP) (frS • sS) (frP' • sP') (frS' • sS') conf oe = Conformant-all-intermediate (frP • sP) (frS • sS) frP' frS' (proj₁ conf) oe

  conf-all++ : {s₁ s₂ s₃ : Stateᴾ} {t₁ t₂ t₃ : State} {tr tr' : Trace}
               (frP : s₁ ⟦ tr ⟧ᴾ*▸ s₂) (frS : t₁ ⟦ tr ⟧*▸ t₂) (frP' : s₂ ⟦ tr' ⟧ᴾ*▸ s₃) (frS' : t₂ ⟦ tr' ⟧*▸ t₃)
             → Conformant-all frP frS → Conformant-all frP' frS'
             → Conformant-all (frP ++RTC frP') (frS ++RTC frS')
  conf-all++ frP frS ∅ ∅ conf conf' = conf
  conf-all++ frP frS (frP' • p) (frS' • s) conf (conf' , oe) = conf-all++ frP frS frP' frS' conf conf' , oe

  Conformant : {tr : Trace} (mr : MultiRecovery tr)
                {s s' : Stateᴾ} (frP : s ⟦ tr ⟧ᴾ*▸ s') → MRFrags mr frP
              → {t t' : State } (frS : t ⟦ tr ⟧*▸  t') → MRFrags mr frS → Set
  Conformant (init _) {s' = s'} _ _ {t' = t'} _ _ = ObsEquiv s' t'
  Conformant (one mr 1r) .(_ ++RTC frP₂) (one {s₂ = s''} frPs frP₂ frPs₂) .(_ ++RTC frS₂) (one {s₂ = t''} frSs frS₂ frSs₂) =
    Conformant mr _ frPs _ frSs × ObsEquiv s'' t'' × Conformant-1R 1r frP₂ frPs₂ frS₂ frSs₂

  BC-all : {tr : Trace} → All Regular×Snapshot tr → {s s' : Stateᴾ} {t : State} →
           SR s t → ObsEquiv s t → (frP : s ⟦ tr ⟧ᴾ*▸ s') →
           Σ[ t' ∈ State ] Σ[ frS ∈ t ⟦ tr ⟧*▸ t' ] SR s' t' × ObsEquiv s' t' × Conformant-all frP frS
  BC-all [] sr oe-s-t ∅ = _ , ∅ , sr , oe-s-t , tt
  BC-all (all ∷ _) sr oe-s-t (frP • _) with BC-all all sr oe-s-t frP
  BC-all (all ∷ _) sr oe-s-t (frP • s''▸s') | t'' , frS'' , sr'' , oe'' , conf'' with simSR sr'' s''▸s'
  BC-all (all ∷ w) sr oe-s-t (frP • w {rinv' = rinv'} rs''▸s') | t'' , frS'' , sr'' , oe'' , conf'' | t' , t''▸t' , ar ar' =
    let oe' = AR⇒ObsEquiv (rinv' , ar') in t' , frS'' • t''▸t' , ar ar' , oe' , conf'' , oe'
  BC-all (all ∷ cp) sr oe-s-t (frP • cp {rinv' = rinv'} rs''▸s') | t'' , frS'' , sr'' , oe'' , conf'' | t' , t''▸t' , ar ar' =
    let oe' = AR⇒ObsEquiv (rinv' , ar') in t' , frS'' • t''▸t' , ar ar' , oe' , conf'' , oe'
  BC-all (all ∷ er) sr oe-s-t (frP • er {rinv' = rinv'} rs''▸s') | t'' , frS'' , sr'' , oe'' , conf'' | t' , t''▸t' , ar ar' =
    let oe' = AR⇒ObsEquiv (rinv' , ar') in t' , frS'' • t''▸t' , ar ar' , oe' , conf'' , oe'
  BC-all (all ∷ f) sr oe-s-t (frP • f {rinv' = rinv'} rs''▸s') | t'' , frS'' , sr'' , oe'' , conf'' | t' , t''▸t' , ar ar' =
    let oe' = AR⇒ObsEquiv (rinv' , ar') in t' , frS'' • t''▸t' , ar ar' , oe' , conf'' , oe'

  BC-1R : {tr : Trace} → (1r : OneRecovery tr) → {s s' : Stateᴾ} {t : State} →
          SR s t → ObsEquiv s t → (frP : s ⟦ tr ⟧ᴾ*▸ s') (frPs : 1RFrags 1r frP) →
          Σ[ t' ∈ State ] Σ[ frS ∈ t ⟦ tr ⟧*▸ t' ] Σ[ frSs ∈ 1RFrags 1r frS ] SR s' t' × ObsEquiv s' t' × Conformant-1R 1r frP frPs frS frSs
  BC-1R 1r sr s=t frP (wᶜ {all₁ = all₁} {all₂ = all₂} fr₁ fr₂ fr₃@(fr₃' • r {rinv' = rinv'} _))
     with BC-all all₁ sr s=t fr₁
  ... | t₁ , frS₁ , sr-s₁-t₁ , s₁=t₁ , conf₁
     with BC-all (([] ∷ f) ++All mapAll r→rs all₂) sr-s₁-t₁ s₁=t₁ fr₂
  ... | t₂ , frS₂ , sr-s₂-t₂ , s₂=t₂ , conf₂ with runSimSR sr-s₂-t₂ fr₃
  ... | t' , frS' , ar ar-s'-t' =
          let oe' = AR⇒ObsEquiv (rinv' , ar-s'-t')
          in  t' , frS₁ ++RTC frS₂ ++RTC frS' , wᶜ frS₁ frS₂ frS' , ar ar-s'-t' , oe' , conf-all++ fr₁ frS₁ fr₂ frS₂ conf₁ conf₂ , oe'
  BC-1R 1r sr s=t frP (fᶜ {all₁ = all₁} {all₂ = all₂} fr₁ fr₂ fr₃@(fr₃' • r {rinv' = rinv'} _))
     with BC-all all₁ sr s=t fr₁
  ... | t₁ , frS₁ , sr-s₁-t₁ , s₁=t₁ , conf₁
     with BC-all (([] ∷ f) ++All mapAll r→rs all₂) sr-s₁-t₁ s₁=t₁ fr₂
  ... | t₂ , frS₂ , sr-s₂-t₂ , s₂=t₂ , conf₂ with runSimSR sr-s₂-t₂ fr₃
  ... | t' , frS' , ar ar-s'-t' =
          let oe' = AR⇒ObsEquiv (rinv' , ar-s'-t')
          in  t' , frS₁ ++RTC frS₂ ++RTC frS' , fᶜ frS₁ frS₂ frS' , ar ar-s'-t' , oe' , conf-all++ fr₁ frS₁ fr₂ frS₂ conf₁ conf₂ , oe'
  BC-1R 1r sr s=t frP (wᶜ-nof {all₂ = all₂} fr₂ fr₃@(fr₃' • r {rinv' = rinv'} _))
     with BC-all (mapAll r→rs all₂) sr s=t fr₂
  ... | _ , frS₂ , sr-s₂-t₂ , s₂=t₂ , conf₂ with runSimSR sr-s₂-t₂ fr₃
  ... | t' , frS' , ar ar-s'-t' =
          let oe' = AR⇒ObsEquiv (rinv' , ar-s'-t')
          in  t' , frS₂ ++RTC frS' , wᶜ-nof frS₂ frS' , ar ar-s'-t' , oe' , conf₂ , oe'
  BC-1R 1r sr s=t frP (fᶜ-nof {all₂ = all₂} fr₂ fr₃@(fr₃' • r {rinv' = rinv'} _))
     with BC-all (mapAll r→rs all₂) sr s=t fr₂
  ... | _ , frS₂ , sr-s₂-t₂ , s₂=t₂ , conf₂ with runSimSR sr-s₂-t₂ fr₃
  ... | t' , frS' , ar ar-s'-t' =
          let oe' = AR⇒ObsEquiv (rinv' , ar-s'-t')
          in  t' , frS₂ ++RTC frS' , fᶜ-nof frS₂ frS' , ar ar-s'-t' , oe' , conf₂ , oe'

  BC-ind : {tr : Trace} (mr : MultiRecovery tr) {s s' : Stateᴾ} → Initᴾ s → (frP : s ⟦ tr ⟧ᴾ*▸ s') (frPs : MRFrags mr frP)
         → Σ[ t ∈ State ] Init t × Σ[ t' ∈ State ] SR s' t' × ObsEquiv s' t' × Σ[ frS ∈ t ⟦ tr ⟧*▸ t' ] Σ[ frSs ∈ MRFrags mr frS ] Conformant mr frP frPs frS frSs
  BC-ind (init all) {s = s₀} (init rs₀) (frP • rP@(r {rinv' = rinv'} rs)) frPs with runSimSR (cr (initᴿ-CR (proj₁ s₀) rs₀ (proj₁ t-init) (proj₂ t-init))) frP
  ... | t'' , frS , sr' with simSR sr' rP
  ... | t' , rS , (ar ar-rs'-t') =
          let eq = AR⇒ObsEquiv (rinv' , ar-rs'-t')
          in  proj₁ t-init , proj₂ t-init , t' , ar ar-rs'-t' , eq , frS • rS , init (frS • rS) , eq
  BC-ind (one mr x) init-s _ (one {mr = mr₁} {fr₁ = frP₁} frPs₁ {1r = 1r} frP₂ frPs₂) with BC-ind mr init-s _ frPs₁
  ... | t , init-t , t'' , sr'' , oe'' , frS₁ , frSs₁ , conf₁ with BC-1R 1r sr'' oe'' frP₂ frPs₂
  ... | t' , frS₂ , frSs₂ , sr' , oe' , conf₂ = t , init-t , t' , sr' , oe' , frS₁ ++RTC frS₂ , one frSs₁ frS₂ frSs₂ , conf₁ , oe'' , conf₂

  BC-mr : {tr : Trace} (mr : MultiRecovery tr) {s s' : Stateᴾ} → Initᴾ s → (frP : s ⟦ tr ⟧ᴾ*▸ s') → (frPs : MRFrags mr frP)
        → Σ[ t ∈ State ] Init t × Σ[ t' ∈ State ] Σ[ frS ∈ t ⟦ tr ⟧*▸ t' ] Σ[ frSs ∈ MRFrags mr frS ] Conformant mr frP frPs frS frSs
  BC-mr mr init-s frP frPs =
    let (t , init-t , t' , _ , _ , frS , frSs , conf) = BC-ind mr init-s frP frPs
    in  (t , init-t , t' , frS ,  frSs , conf)

  BC : {tr : Trace} (mr : MultiRecovery tr) {s s' : Stateᴾ} → Initᴾ s → (frP : s ⟦ tr ⟧ᴾ*▸ s') (frPs : MRFrags mr frP)
     → {tr' : Trace} {s'' : Stateᴾ} → All Regular×Snapshot tr' → (frP' : s' ⟦ tr' ⟧ᴾ*▸ s'')
     → Σ[ t ∈ State ] Init t × Σ[ t' ∈ State ] Σ[ frS ∈ t ⟦ tr ⟧*▸ t' ] Σ[ frSs ∈ MRFrags mr frS ] Σ[ t'' ∈ State ] Σ[ frS' ∈ t' ⟦ tr' ⟧*▸ t'' ]
       Conformant mr frP frPs frS frSs × Conformant-all frP' frS'
  BC mr init-s frP frPs all frP' =
    let (t , init-t , t' , sr' , oe' , frS , frSs , conf) = BC-ind mr init-s frP frPs
        (t'' , frS' , _ , _ , conf') = BC-all all sr' oe' frP'
    in  (t , init-t , t' , frS , frSs , t'' , frS' , conf , conf')

  SC : {s₀ s s' : Stateᴾ} {tr₀ tr : Trace} → (mr : MultiRecovery tr₀) → (1r : OneRecovery tr)
     → Initᴾ s₀ → (fr₀ : s₀ ⟦ tr₀ ⟧ᴾ*▸ s) → MRFrags mr fr₀ → (frP : s ⟦ tr ⟧ᴾ*▸ s') → (frPs : 1RFrags 1r frP)
     → SnapshotConsistency (λ{(rs , _) (rs' , _) → read rs ≐ read rs'}) 1r frP frPs
  SC mr 1r init-s₀ frP₀ frPs₀ frP frPs with BC-mr (one mr 1r) init-s₀ (frP₀ ++RTC frP) (one frPs₀ frP frPs)
  SC mr ._ init-s₀ frP₀ frPs₀ ._ (wᶜ frP₁ frP₂ frP₃) |
     t₀ , init-t₀ , t' , ._ , one frSs ._ (wᶜ {all₁ = all₁} {all₂ = all₂} {all₃ = all₃} frS₁ frS₂ frS₃) , (_ , oe-s-t , conf , oe-s'-t')
       = Conformant-all-intermediate frP₁ frS₁ frP₂ frS₂ conf oe-s-t <≐> SpecSC-wᶜ ⦃ all₂ ⦄ ⦃ all₃ ⦄ frS₂ frS₃ <≐> sym-≐ oe-s'-t'
  SC mr ._ init-s₀ frP₀ frPs₀ ._ (fᶜ frP₁ frP₂ frP₃) |
     t₀ , init-t₀ , t' , ._ , one frSs ._ (fᶜ {all₁ = all₁} {all₂ = all₂} {all₃ = all₃} frS₁ frS₂ frS₃) , (_ , oe-s-t , conf , oe-s'-t')
       with SpecSC-fᶜ {{all₂}} {{all₃}} frS₂ frS₃
  ...  | inj₁ req = inj₁ $ Conformant-all-intermediate (frP₁ ++RTC frP₂) (frS₁ ++RTC frS₂) ∅ ∅ conf oe-s-t <≐> req <≐> sym-≐ oe-s'-t'
  ...  | inj₂ req = inj₂ $ Conformant-all-intermediate frP₁ frS₁ frP₂ frS₂ conf oe-s-t <≐> req <≐> sym-≐ oe-s'-t'
  SC mr ._ init-s₀ frP₀ frPs₀ ._ (wᶜ-nof frP₂ frP₃) |
     t₀ , init-t₀ , t' , ._ , one {fr₁ = frS₀} frSs ._ (wᶜ-nof {all₂ = all₂} {all₃ = all₃} frS₂ frS₃) , (_ , oe-s-t , conf , oe-s'-t')
       = oe-s-t <≐> SpecSC-wᶜ-nof ⦃ all₂ ⦄ ⦃ all₃ ⦄ (proj₂ (lastr mr frS₀ frSs)) frS₂ frS₃ <≐> sym-≐ oe-s'-t'
  SC mr ._ init-s₀ frP₀ frPs₀ ._ (fᶜ-nof frP₂ frP₃) |
     t₀ , init-t₀ , t' , ._ , one frSs ._ (fᶜ-nof {all₂ = all₂} {all₃ = all₃} frS₂ frS₃) , (_ , oe-s-t , conf , oe-s'-t')
       with SpecSC-fᶜ-nof {{all₂}} {{all₃}} (proj₂ (lastr mr _ frSs)) frS₂ frS₃
  ...  | inj₁ req = inj₁ $ Conformant-all-intermediate frP₂ frS₂ ∅ ∅ conf oe-s-t <≐> req <≐> sym-≐ oe-s'-t'
  ...  | inj₂ req = inj₂ $ oe-s-t <≐> req <≐> sym-≐ oe-s'-t'
