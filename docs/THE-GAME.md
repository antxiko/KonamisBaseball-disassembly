# The game

**Konami's Baseball** is a baseball match for one or two players. It came out
in 1984, it is **RC-724** in Konami's catalogue, and it takes 16 KB.

Everything on this page is read off the binary. Where something could not be
checked, it says so.

## Choosing a game

The title screen offers **1 PLAYER** and **2 PLAYERS**. With one, the machine
plays the other side; with two, the second player uses the second joystick or
their half of the keyboard.

Below that comes the league choice: **CENTRAL** and **PACIFIC**. And with the
league chosen, the grid of six teams, each by its initial:

| Central | | Pacific | |
|---|---|---|---|
| **C** | Carp | **B** | Braves |
| **D** | Dragons | **Bu** | Buffaloes |
| **G** | Giants | **F** | Fighters |
| **S** | Swallows | **H** | Hawks |
| **T** | Tigers | **L** | Lions |
| **W** | Whales | **O** | Orions |

These are the twelve teams of **1984 Nippon Professional Baseball**,
alphabetical within each league. The cartridge never writes the names anywhere:
only the initials, in the twelve bytes at 0x4649. The **Bu** for the Buffaloes
is a tile made on purpose, 0xE8, so it is not mistaken for the Braves' B.

The only thing that tells one team from another is **two bytes**, the ones
0x5b5a pulls from the tables at 0x5b9c and 0x5ba8 and drops into slots 0x0c and
0x10 of the pitcher's and batter's records. There are no rosters and no
statistics: two numbers per team.

## The controls

The first player can use the joystick in the first port or **the four cursor
keys plus the space bar** (0x436e). The second, the second port or **W up, Z
down, A left, D right and SHIFT** (0x432a).

Both keyboard reads are rearranged into the order the rest of the cartridge
wants, which is the joystick's: bit 0 up, 1 down, 2 left, 3 right, 4 and 5 the
buttons. The cursor-key read is translated in one go with the sixteen-entry
table at 0x4396, in which the six impossible combinations - up and down at once,
left and right at once - all read 0x0F.

## Pitching

Before the pitch there is a **meter** that fills and empties by itself, bottom
left: fifteen cells and a BCD counter that climbs to 60 and then comes back down
(0x4fc3). The high nibble of 0xE364 and the two pairs of bits in the low one are
the pitch's speed and break.

With the pitch wound up, the arm goes through **six poses**, one every five
frames (0x4d74). On the sixth it lets go of the ball, and from there 0x4dac is
in charge: the ball advances by adding the step at 0xE125 to a 16-bit
accumulator, and the whole byte that falls out is how far it moves. Every three
turns of the counter at 0xE127 it is given a new step from the table at 0x4f97:
that is the **break**.

## Batting

The bat has **five poses** per kind of swing (table at 0x4faf), and advances for
as long as the button is held. There is contact if the ball enters the contact
box - one of the three at 0x730a, two limits per axis - and the bat is in pose
2, 3 or 4.

**Where** the ball enters the bat is what gives the angle it flies off at: the
table at 0x728a holds fifteen angles per side of the batter - three poses by
five columns - running from 0x3c down to 0x04 and back up to 0x3c, that is, from
one extreme to the other. To the angle are added **two bits of the Z80's R
register** (0x714b), so no two hits are exactly alike.

## Running

The four bases are four 32-byte records at 0xE180. A runner takes off when the
direction of that base is pressed together with the button, and there is a nice
check in 0x44ed: if the step would land him on the base the other player already
holds, he takes one more step the same way.

With one player, the machine decides on its own which runner to send: it walks
the four bases, keeps the one furthest along in each direction, and **writes the
order into 0xE011**, the very byte where the second player's freshly pressed
bits live.

## Counting

The counters all sit together from 0xE408: strikes, balls, outs, the inning, and
each team's runs. Three strikes make an out, three outs change the inning, and
**four balls** are a walk - and out comes the "4 BALL" card, written with tile
0xF4, the digit four, in front of the word.

There are seven cards, in the table at 0x7c20, each with its sound: **STRIKE**,
**BALL**, **OUT**, **SAFE**, **CHANGE**, **FOUL** and that **4 BALL**. And
separately **HOME RUN**, which blinks against the empty frame every 32 frames.

## How many innings

Nine. 0x7b36 bumps the counter at 0xE40B every time the second team's turn ends,
and on reaching **nine** it sets 0xE402 to 0x80, which is what the outer loop
watches to call the match over.

There is one exception: in the **eighth**, if the two scores are level, 0x7b7b
writes an 0xE7 into the cell and the match carries on. So there is something
like extra innings on a tie. **ASSUMPTION**: nobody has played a whole match
through to see it.
