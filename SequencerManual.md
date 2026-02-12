# Sequencer Manual

## Definitions

The following terms are used throughout this manual:

### Sequence
A sequence can be thought of as a segment of multitrack tape of
variable length. Depending on the sequence contents, it could be a
two-bar repeating drum pattern, an eight-bar verse, or an entire
200-bar multitrack composition with time signature and tempo
changes. The sequencer holds 99 sequences in memory at one time.
Normally, only one sequence can play at one time, unless the Simul
Sequence feature is on, which allows two sequences or one sequence
and one song to play simultaneously.

### Track

Within each of the 99 sequences are 99 tracks that contain the
actual MIDI events. These can be thought of as the tracks on a
multitrack tape recorder—they each contain a specific instrument or
piece of the total arrangement, but they all play simultaneously. For
example, track 1 could be drums, track 2 percussion, track 3 bass,
track 4 piano, track 5 horns, track 6 more horns, etc. Each track can
be assigned as a Drum track or a MIDI track, but not both. MIDI
tracks contain normal MIDI data recorded from the MIDI input and
played out through the MIDI output. Drum tracks are the same as
MIDI tracks except for the following:
1. The output of the track plays to the internal drum sound
generator.
2. You can record drum notes into the track using the front
panel pads.
3. In sequence editing screens, note events in drum tracks
are visually identified and selected not by note number
only as in MIDI tracks, but also by the pad number and
sound name currently assigned to the displayed note
number.
4. Drum tracks are not affected by the Transpose function.

### Song
A song is a list of sequences that play consecutively, with each
sequence representing a section of a composition. In the sequencer
there are 20 songs, each having up to 250 steps. Each step holds
one sequence and can repeat a specified number of times before the
song moves to the next step.

### Sound

Each individual sampled recording in the sequencer is called a
sound. A sound could be a recording of a single strike of a snare
drum or cymbal, a sound effect, or a 30 second stereo recording of
backing vocals. Sounds are sampled in 16-bit linear format at a
sampling rate of 44.1kHz in either mono or stereo and can be any
length up to the limit of sound memory. A maximum of 128 sounds
can reside in sound memory.

### Pad
When sounds are loaded into the sequencer, each pad plays a
particular sound. Though there are only 16 pads, the sequencer can
hold many more than 16 sounds, To access more than 16 sounds
from the pads, the sequencer provides four banks of pad assign-
ments permitting up to 64 sounds to be played from the 16 pads.
Only one bank can be active at a time. The four banks are named A,
B, C, and D, and the pads are numbered 1 through 16. The 64 bank/
pad combinations are named by combining the bank letter (A-D)
with the pad number:
Pads in bank A: A01 through A16
Pads in bank B: B01 through B16
Pads in bank C: C01 through C16
Pads in bank D: D01 through D16
Each of these 64 bank/pad combinations (A01-D16) is referred to as
a pad.
Notice that sounds are not assigned directly to pads, but rather to
MIDI Note Numbers. In order for a pad to play a sound, it is first
assigned to a MIDI note number, then that note number is assigned
to a sound. This is described further in the “MIDI Functions” and
“Creating and Editing Programs” chapters of this manual.

### Note Number

In MIDI terminology, note number refers to the element in a MIDI
Note On event that supplies the pitch of the note. The note number
range is from 0 to 127. For example, if Middle C is played on a MIDI
keyboard, a Note On event is sent out over MIDI containing note
number 60; the receiving sound generator interprets this as Middle
C and plays the appropriate pitch. If the sound generator is playing
drum sounds, the note number is not used for pitch, but rather to
select which drum will play—one key for bass drum, one for snare,
one for high tom, etc.
This system of using MIDI note numbers to select drums is used in
the sequencer’s sound assignment system. In programs (described
below), sounds are assigned directly to one of 64 MIDI note numbers
(35-98). In sequences, drum notes are also assigned to one of 64 note
numbers (35-98) to indicate which sound to play. Because of this
assignment method, there are many data fields in the sequencer
called Note, in which you enter either the note number you wish to
assign in a program, or the note number you wish to edit in a
sequence’s drum track. (For easy visual identification in these
Note fields, the note number is accompanied by both the currently
assigned pad number and sound name.)

### Program
Once a sound is loaded into memory, it cannot be played by pads or
from MIDI until it is assigned within a program. A program is a
collection of 64 sound assignments and can be thought of as a drum
set. In a program, each of 64 MIDI note numbers (35-98) is assigned
to one of the 128 possible sounds currently residing in memory. Once
assigned to a note number, a sound can be played in one of three
ways:
1. By receiving a Note On message from the MIDI input;
2. By playing a front panel drum pad (each pad is also assigned to
one of the 64 MIDI note numbers 35-98);
3. By playing drum tracks in sequences (each note event in a drum
track is assigned to one of the 64 MIDI note numbers 35-98).
In addition to the 64 sound assignments, each program also con-
tains a number of sound modifying parameters for each of the 64
sound assignments, including envelope, tuning, filter, mixer, and
velocity response data. Each program also contains some param-
eters, such as the settings of the effects generator, that collectively
affect all sounds.
The sequencer has 24 different programs (one of which can be active
at a time) each with its own unique set of 64 assignments. Simply by
changing the active program number (1-24), all 64 sound assign-
ments and their sound modifying settings will instantly change.

---

## How Sequences are Organized

A sequence can be thought of as a segment of multitrack tape of
variable length. Depending on the sequence contents, it could be a
two-bar repeating drum pattern, an eight-bar verse, or an entire
200-bar multitrack composition with time signature and tempo
changes. The sequencer holds 99 sequences in memory at one time.
Normally, only one sequence can play at one time, unless the Simul
Sequence feature is on, which allows two sequences, or one sequence
and one song, to play simultaneously.
Within each of the 99 sequences are 99 tracks that contain the
actual MIDI events. These can be thought of as the tracks on a
multitrack tape recorder—they each contain a specific instrument or
piece of the total arrangement, but they all play simultaneously. For
example, track 1 could be drums, track 2 percussion, track 3 bass
guitar, track 4 piano, track 5 horns, track 6 more horns, etc. Each
track can be assigned as a Drum track or a MIDI track, but not
both. MIDI tracks contain normal MIDI data recorded from the
MIDI input and played out through the MIDI output. Drum tracks
are the same as MIDI tracks except for the following:
1. The output of the track plays to the internal drum sound
generator.
2. You can record drum notes into the track using the front
panel pads.
3. In sequence editing screens, note events in drum tracks
are visually identified and selected not by note number
only as in MIDI tracks, but also by the pad number and
sound name currently assigned to the displayed note
number.
4. Drum tracks are not affected by the Transpose function.
In order for the sequencer to play external synthesizers, it must
send its notes out through MIDI on one of the 64 output MIDI
channels (16 channels for each of the 4 MIDI output jacks). On the
sequencer, each track can be independently assigned to output its
notes through any one or two of these 64 output MIDI channels.

### Ticks and Bar.Beat.Tick Fields

The timing resolution of the sequencer is 96 divisions per quarter
note (96 ppq). Each one of these divisions is called a tick.
In many of the sequence editing screens it is necessary to enter the
start and end of the region to be edited. This is done using a three-
part field, called a bar.beat.tick field, containing a bar number,
beat number, and tick number. (A beat is the timing value of the
lower half of the time signature. For example, in 4/4 time, a beat is
one quarter note.) In bar.beat.tick fields, you enter the three parts
separated by decimal points (.), followed by ENTER. For example, to
enter bar 1, beat 3 and tick 24, type 1, decimal point, 3, decimal
point, 24, ENTER. If you only want to enter the bar number, type it
followed by ENTER—The beat and tick portions will be reset to the
start of the bar.

---

## The MAIN SCREEN Key & Play/Record Screen

When the sequencer is first powered on, the LCD screen shows the
following contents:

```
============== Play/Record =============
Seq: 1-(unused) BPM:120.0 (SEQ)
Sig: 4/ 4 Bars: 0 Loop:TO BAR 1
============== Track Data ==============
Trk: 1-(unused) Type:DRUM On:YES
Chn:OFF-(off) & OFF Vel%:100 Pgm:OFF
===== Now:001.01.00 (00:00:00:00) ======
<Tk on/off> <Solo=OFF> <Track-> <Track+>
```

This is called the Play/Record screen. It is the main operating
screen of the sequencer and most playing and recording of sequences
is done while this screen is showing. To return to this screen at any
time, press the MAIN SCREEN key. The following is an explanation of each of the data fields and soft keys contained in this screen:

#### The Title Line

• The title line (===== Play/Record =====) :
The title line not only displays the title of this screen but also
indicates whether Record Ready status is enabled or disabled by
appearing in one of two views:
1. Record disabled:
========== Play/Record ============
This is the normal mode for sequence playing. In this mode,
it is impossible to “punch in” to Record or Overdub mode
while playing the sequence. However, in this mode it is
possible to change sequences while playing. To do this,
simply select a new sequence while playing using the
numeric keypad. When the previously selected sequence
finishes, the newly selected one begins playing. This feature
is very useful for creating the structure of a song in real
time while the sequencer is playing.
COMMENT: If you use the data entry control to select
a new sequence while playing, only the next higher-
numbered or next lower-numbered sequence can be
selected. If you want to select a sequence whose
number is greater than one higher or lower, you must
use the numeric keypad (remember to press ENTER
after you have entered the new sequence number).
2. Record ready:
==== Play/Record (Record ready) ===
In this mode, it is possible to “punch in” to Record or
Overdub mode while playing the sequence. To punch
in: while playing a sequence, hold both PLAY and either
RECORD or OVERDUB simultaneously—the sequencer will
immediately enter either Record or Overdub mode. In this
mode it is impossible to change sequences while playing.

#### The Sequence Number Field

• The Sequence Number field (Seq: 1 1 1 1 1-(unused) in the example
screen):
This field displays the active sequence number, from 1 to 99. This is
the sequence that will play when either PLAY START or PLAY is
pressed. If you change the sequence number while a sequence is
playing, the new sequence will start playing when the current
sequence finishes playing.
COMMENT: If you select a new sequence number while
playing by using the data entry control, only the next higher
or next lower sequence can be selected. To select other se-
quences while playing, use the numeric keypad.

#### The Sequence Name Field

• The Sequence Name field (Seq: 1 1 1 1 1-(unused) in the example
screen):
This is the 16-character name for the active sequence. To change the
sequence name, move the cursor to this field and turn the data
entry control one step in either direction. This will cause the keys
that have alphabet letters printed above them to function as alpha-
bet entry keys. To indicate that alphabet mode is active, the cursor
changes from the normal blinking block to a blinking underline.
Now change the name by typing the letters printed above the keys.
The CURSOR LEFT and CURSOR RIGHT keys do not type letters,
but allow you to move the cursor left or right within the name. For
punctuation, use the data entry control. When finished, press
ENTER and the cursor will return to a blinking block at the begin-
ning of the field, indicating that the alpha keys have returned to
their normal functions. To discard any changes and return to the old
name before ENTER is pressed, press and release HELP.
• The Tempo Display Mode field (BPM BPM BPM BPM BPM:120.0 (SEQ) in the
example screen):
This is a choice field with two options:
1. BPM: The tempo is displayed in Beats Per Minute with
one digit to the right of the decimal point.
2. FPB: The tempo is displayed in Frames Per Beat with one
digit to the right of the decimal point indicating 1/8s of a
frame. If this option is selected, the Frames field (in the
Tempo/Sync screen)
should be set to the desired frame rate.
• The Active Tempo field (BPM:120.0 120.0 120.0 120.0 120.0 (SEQ) in the above ex-
ample):
This is the active playing tempo. If the sequence contains tempo
changes, this shows the active tempo at the current sequence
position displayed in the Now field.
• The Tempo Source field (BPM:120.0 (SEQ) (SEQ) (SEQ) (SEQ) (SEQ) in the above
example):
This is a choice field with two options:
1. SEQ (sequence): Within each sequence is a unique tempo
setting. If this option is selected, the sequence’s unique
tempo is used in the Active Tempo field. In this case,
whenever the active sequence number is changed, the
newly selected sequence’s tempo immediately appears in
the Active Tempo field. When playing sequences, this is
useful if you want each newly selected sequence to play
at its own preset tempo. The sequence’s tempo is saved to
disk when a sequence is saved.
2. MAS (master): The master tempo is a single tempo setting
that applies to all sequences and songs. When playing
sequences this is useful if you always want each newly
selected sequence to play at the same tempo. This tempo
setting is not saved in the sequence file.
• The Time Signature field (Sig: 4/ 4/ 4/ 4/ 4/ 4 4 4 4 4 in the above example):
This field shows the time signature of the current bar (displayed in
the Now field) of the active sequence. It is for display only and
cannot be changed. For information on how to change the time
signature of a bar or to insert time signature changes, see the
“Editing Sequences” chapter of this manual.
• The Bars field:
This shows the total number of bars in the active sequence. It is for
display only and cannot be changed.
• The Loop field:
This is a choice field with two options:
1. OFF:
If this option is selected, the sequence stops playing when
it reaches its end. However, if in Record mode, recording
continues past the end, adding one measure (at the time
signature of the last bar) onto the end of the sequence as
each new bar is entered, until the sequence is stopped.
2. TO BAR 1:
If this option is selected, when the sequence plays to the
end, it immediately loops back to the bar number
displayed to the right of the word BAR. To set the
number of the bar to which the sequence loops back,
move the cursor to the field to the right of the word
BAR and enter the new number.
COMMENT: If the bar to loop to is bar number 1 and
the sequence is in Record mode, the sequencer will
automatically switch from Record to Overdub mode at
the moment the sequence loops back—this will prevent
accidental erasure of any notes just recorded. In the
event that the bar to loop to is bar number 2 or higher
and the sequence is in Record or Overdub mode the
sequencer will automatically switch to Play mode at
the moment the sequence loops back to the specified
bar.
### The Track Data Area (lines 4-6)

• The Active Track field (Trk: 1 1 1 1 1-(unused) in the example
screen):
This field displays the active track number within the sequence. The
active track is the track that, when Record or Overdub mode is
entered, will be recorded into from the MIDI keyboard or pads. Also,
if the Soft thru field is on (described in the “MIDI Functions”
chapter of this manual) and the pads or MIDI keyboard is played,
the played notes will be sent out over MIDI in real time using the
active track’s MIDI channel and port assignments. Only one track
can be active at a time.
• The Track Name field (Trk: 1-(unused) (unused) (unused) (unused) (unused) in the example
screen)
This field has no on-screen title, but is the 16-character name of the
active track, and is located directly to the right of the active track
number. It is changed in the same manner as the sequence name,
detailed above.
• The Type field:
This is a choice field with two options—MIDI and DRUM:
1. MIDI: Select this option if you want to record normal
non-drum MIDI data from an external MIDI keyboard
into the selected track. MIDI tracks do not use the
internal sound generator or pads.
2. DRUM: Select this option if you want to record drum data
into the selected track. Drum tracks are the same as
MIDI tracks except for the following:
A. The output of the track plays to the internal
drum sound generator.
B. You can record drum notes into the track using
the front panel pads.
C. In sequence editing screens, note events in
drum tracks are visually identified and
selected not by note number only as in MIDI
tracks, but also by the pad number and sound
name currently assigned to the displayed note
number.
D. Drum tracks are not affected by the Transpose
function.
• The Track On/Off field (On:YES YES YES YES YES in the example screen):
This choice field turns the output of the active track on (YES) or off
(NO). Pressing SOFT KEY 1 toggles the field’s state between YES
and NO.
• The MIDI Channel/Port fields (Chn:OFF OFF OFF OFF OFF-(off) in the example
screen):
There are actually two fields here, which together are used to
determine which MIDI channel and MIDI output port the active
track will output its data to. The to fields are:
1. The MIDI Channel field (Chn: 1 1 1 1 1A-(off)):
This field determines which of the 16 MIDI channels the
active track will play through. If you don’t want the track
to play through any MIDI channels, select 0 and the word
OFF will appear.
2. The MIDI Port field (Chn: 1A A A A A-(off)):
This choice field determines which of the four MIDI
output ports (A, B, C, or D) the active track will play
through. (If OFF is selected in the MIDI channel field to
the left, this field can’t be seen.)
COMMENT: If OFF is displayed in this field (no MIDI
output assignment) and you want to select a MIDI channel or
port, first move the cursor to the letter “O” of OFF and turn
the data entry control one step to the right.
• The MIDI Channel/Port Name field (Chn:OFF-(off) (off) (off) (off) (off) in the
example screen):
This is the eight-character name for the currently selected MIDI
output channel/port combination. This would commonly contain the
name of the synthesizer that is being played from the displayed
MIDI channel/port combination. There are 64 names—one for each
of the 64 output MIDI channel/port combinations. The name is
changed in exactly the same way as the sequence name field.
COMMENT: These 64 names are intended to be used to
identify the MIDI devices that are externally connected—not
the data contained in the track. For this reason, they are not
saved within sequence files or ALL files. They are, however,
retained in memory after power is removed and are also
saved within Parameter files.
• The Auxiliary MIDI Channel/Port fields (& OFF in the example
screen):
These two fields have exactly the same function and operation as
the MIDI Channel/Port fields shown to the left. These two
fields allow the active track to play simultaneously through an
additional channel/port combination. If no additional output chan-
nel/port is desired, select OFF here.
• The Velocity% field (Vel%:100 100 100 100 100 in the example screen):
This is an overall output volume control for active track. However,
unlike a normal volume control, this function actually scales the
velocities of all notes that play from the track in real time, acting as
a real-time dynamics control. The range is from 0 to 200%. Values
from 0 to 99 reduce velocities; values from 101 to 200 increase them.
Select 100 for no effect.
• The Program Number field (Pgm:OFF ):
This field permits a MIDI program number (1-128) to be assigned to
the active track. To select no program assignment for the active
track, enter a 0 in this field and OFF will be displayed. Whenever a
new sequence is selected, if any of the sequence’s tracks contain
program number assignments, those program numbers will be
immediately sent out over the track’s assigned MIDI channel/port
(not the auxiliary MIDI channel/port) to the external synthesizer,
causing it to change to the assigned program number. This way, all
external synthesizers are immediately changed to the correct
program numbers by merely selecting the sequence. If a track’s
Type field is set to DRUM, the assigned program number will
change the internal sound generator’s active program number.
COMMENT: It is also possible to record MIDI program
change events at any location within a track, either in real
time or in Step Edit mode. (See the “Step Edit” section in
the “Editing Sequences” chapter of this manual for more
details about this.) It is important to note that if one of these
program change events is inserted mid-sequence and the
portion of the sequence containing the change is played
(causing the external synthesizer to change to the new pro-
gram), the original program number (as set up in the Pro-
gram Number field) will not be re-sent over MIDI until the
sequence is reselected in the Sequence Number field. Simply
restarting the sequence will not implement the program
change. If the sequencer did send out all assigned program
numbers whenever PLAY START were pressed, this problem
would be corrected, but there would also be a brief delay at
the start of the sequence because the external synthesizers
must take time to change their program data. If you do want
a program change to be sent out whenever PLAY START is
pressed, it is better to insert a MIDI Program Change event
at the start of the track, using Step Edit.
• The Now field (Now:001.01.00 001.01.00 001.01.00 001.01.00 001.01.00 (00:00:00:00 00:00:00:00 00:00:00:00 00:00:00:00 00:00:00:00) in the
example screen):
This field displays the current position within the sequence. The left
side of this field shows the current position in musical terms—as a
three-part number separated by decimal points.
The first part is the bar number; the second is the beat number
within the bar (the beat is equal to the denominator of the time
signature); and the third is the tick number within the beat (there
are 96 ticks to a quarter note). Bars and beats start at 1; ticks start
at 0.
To the right of the above-described bar.beat.tick number is another
four-part number, displayed in parentheses. This field shows the
current position of the sequence as a function of elapsed time from
the beginning of the sequence, in hours, minutes, seconds, and
frames. However, the number displayed when the sequence is set to
the start is not necessarily 00:00:00:00, but rather is equal to the
SMPTE start time. SMPTE operation is described in the chapter 10:
“Syncing to Tape and Other Devices”.
This field is for display only and cannot be edited directly with the
cursor. It is normally changed by using the REWIND, FAST FOR-
WARD and LOCATE keys, described in the “Play/Record Keys”
section of this chapter. These fields change in real time while the
sequence plays. However, the right-most part of each field—the ticks
and frames parts—are replaced with two dashes (—) while playing
because they would otherwise change too quickly to be useful.
### The Four Soft Keys

• The <Tk on/off> soft key:
Pressing this soft key toggles the Track On/Off field between YES
and NO.
• The <Solo=OFF> soft key:
Pressing this soft key turns solo mode ON or OFF. If set to ON, only
the active track is heard and all other tracks are temporarily muted.
The text of the soft key indicates whether solo mode is ON or OFF.
• The <Track-> soft key:
Pressing this soft key decrements the active track number by one.
• The <Track+> soft key:
Pressing this soft key increments the active track number by one.

---

## The Play/Record Keys

These ten keys operate similarly to the transport keys on a tape
recorder, with some very useful additions:
• The PLAY START key:
This key causes the active sequence to begin playing from the start
of bar 1.
• The PLAY key:
This key causes the sequence to begin playing from the current
position displayed in the Now field in the Play/Record screen.
• The STOP key:
This key causes the sequence to stop playing.
• The OVERDUB key:
This key, when held down while PLAY is pressed, causes Overdub
mode to be entered, in which new notes can be recorded into the
active track without erasing existing notes. While Overdub mode is
active, the light above the OVERDUB key is on.
It is also possible to punch-in to Overdub mode while playing. To do
this:
1. The sequencer must be in Record Ready mode. (The top
line of the Play/Record screen must display the words
Play/Record (Record ready).) If not, simply
press and release the RECORD or OVERDUB key once
while the sequence is stopped.
2. While the sequence is playing, simultaneously press the
OVERDUB and PLAY keys. Overdub mode is now active,
indicated by the light above the OVERDUB key.
To punch-out of Overdub mode, simply press the OVERDUB key
once, and the light above the OVERDUB key will turn off.
COMMENT: If Overdub mode is entered while the sequence
is set to loop to a higher-numbered bar than bar number1,
Overdub mode will automatically be turned off at the mo-
ment the sequence reaches the end and starts to loop.
• The RECORD key:
This key, when held down while PLAY is pressed, causes Record
mode to be entered, in which new notes can be recorded into the
active track while existing notes are erased, just as with a tape
recorder. While Record mode is active, the light above the RECORD
key is on.
It is also possible to punch-in to Record mode while playing. To do
this:
1. The sequencer must be in Record Ready mode. (The top
line of the Play/Record screen must display the words
Play/Record (Record ready).) If not, simply
press and release the RECORD or OVERDUB key once
while the sequence is stopped.
2. While the sequence is playing, simultaneously press the
RECORD and PLAY keys. Record mode is now active, as
indicated by the light above the RECORD key.
To punch-out of Record mode, simply press the RECORD key once,
and the light above the RECORD key will turn off.
COMMENT: If Record mode is entered while the sequence is
set to loop to bar number1 (or a portion of the sequence is
looped with the Edit Loop function), Record mode automati-
cally switches to Overdub mode at the moment the sequence
reaches the end and starts to loop. This prevents accidental
erasure of any data that were recorded on the previous pass
through the loop. If, however, Record mode is entered while
the sequence is set to loop to a higher-numbered bar than bar
1, Record mode will automatically be turned off at the
moment the sequence reaches the end and starts to loop.
COMMENT: If an empty sequence is selected (the sequence
name field shows “unused”), and either RECORD or OVER-
DUB is pressed, the sequence will instantly be initialized
using the settings in the Initialize Sequence screen. This
function is normally accessed by pressing the ERASE key
and selecting SOFT KEY 2.
• The REWIND [<<] and FAST FORWARD [>>] keys:
Use these two keys to change the current position within the se-
quence to either the previous or next bar boundary. The actions of
these keys repeat when they are held.
• The REWIND [<] and FAST FORWARD [>] keys:
Use these two keys to move the current position within the sequence
to either the previous or next note boundary, as determined by the
value in the Note Value field of the Timing Correct screen
(normally set to 1/16 NOTE). To change the amount of movement,
simply change the setting in this data field. The actions of these
keys repeat when they are held.
While the Step Edit function is active, it is possible to set these keys
to an alternate function—to search to the previous or next event of a
specific type within the track. To learn how to do this, see the “Step
Edit Options” section in the “Editing Sequences” chapter of this
manual.
• The LOCATE key:
This key is used to instantly move to a specific position within the
active sequence. When pressed, the following screen is displayed:

```
================ Locate ================
Hit softkeys or LOCATE to go to markers:
Marker A: 001.01.00
Marker B: 001.01.00
Marker C: 001.01.00
===== Now:001.01.00 (00:00:00:00) ======
<Goto A> <Goto B> <Goto C> <Load'Now'>
```

There are three sequence position markers, labeled A, B, and C.
Pressing SOFT KEY 1, 2 ,or 3 causes the sequencer to move immedi-
ately to the location shown in either marker A, B, or C, respectively,
and the Play/Record screen to be redisplayed. Pressing SOFT KEY
4, <Load'Now'>, causes the contents of the Now field to be loaded
into the marker field that currently contains the cursor. To load any
of the three markers, move the cursor to it and enter the desired bar
numbers in the format bar.beat.tick (separated by decimal points),
using the numeric keypad. If you only want to enter the bar number,
type it, followed by ENTER, and the beat and tick numbers will be
automatically reset to 01.00.
There is a faster way to use locate. While the Locate screen is
showing, press the LOCATE key again, and the sequencer will
immediately move to the sequence location of the marker (A, B, or
C) where the cursor is currently positioned, exactly as if the SOFT
KEY for that marker (SOFT KEY 1, 2, or 3) had been pressed.
Therefore, from the Play/Record screen, “double-clicking” LOCATE
will instantly move to location A, B, or C, depending on where the
cursor was last positioned in the Locate screen.

---

## Sequence Recording Example 1: A Looped Drum Pattern
The sequencer is both a linear-type sequencer and a pattern-ori-
ented sequencer. The following examples use short, looped se-
quences and are therefore examples of pattern-oriented recording.
To record linearly, simply set the Loop field (in the Play/Record
screen) to OFF. Then, the sequence length will automatically in-
crease as you record past the existing end. See the description of the
Loop field to learn more about this.
The following is a step-by-step example of how to record a repeating
two-bar drum sequence:
1. Load some sounds into sound memory by loading a program file
from one of the sound disks included with your sequencer. If you
don’t know how to do this, see the chapter “Saving To and Load-
ing From Disk”.
2. Press MAIN SCREEN to view the Play/Record screen.
3. Move the cursor to the Seq field and select 1 (ENTER) or any
other empty sequence.
4. The upper line of the screen should display:
====== Play/Record (Record ready) ======
If not, press either the RECORD or OVERDUB keys once. This will
make the current sequence ready for recording.
5. Set the Trk field to 1 and the Type field to DRUM.
6. While holding RECORD, press PLAY START. The RECORD and
PLAY lights should go on, and the metronome should be heard
through the stereo outputs. The metronome will play on 1/4-
notes, with a louder click at the start of each bar. Also, the Now
display will be constantly changing to reflect the current position
within the sequence. If you want to adjust the tempo, move the
cursor to the Active Tempo field (to the right of the word BPM in
the upper left corner) and enter the desired tempo.
7. Start recording your drum pattern by playing the drum pads in
time to the metronome. Since no specific format of time signature
or number of bars has been entered, the sequence format defaults
to two bars of 4/4 time signature. When the two-bar pattern loops
back to the start, Record mode switches automatically to
Overdub mode to avoid erasing your new notes. The notes you
played will be heard at the position they were recorded, except
that the Timing Correct function has automatically moved all of
your notes to the nearest 1/16-note. (This can be defeated, as
explained in “The TIMING CORRECT Key” section, later in this
chapter.)
8. Press STOP.
COMMENT: To initialize a sequence to a different time
signature or number of bars, press ERASE and select
<Initialize>.
If you don’t think your pattern sounds as good as you intended, you
may need some practice in following the metronome. If you want to
erase what you’ve just recorded and start again, simply repeat steps
6 through 8 above.
To erase a particular drum from your new sequence

1. Press the ERASE key. The following screen will appear:

```
================= Erase ================
Seqnc: 1-SEQ01
Track: 1-TRK01 (0 = all)
Ticks:001.01.00-003.01.00
Erase:ALL EVENTS
Notes:ALL (Hit pads)
========================================
<Do it> <Initialize><Delete><Delete All>
```

2. To select a particular drum to erase, press the drum pad that was
used to record its notes. Immediately, the Notes field will
display the note number (35-98), pad number, and currently
assigned sound for the selected pad. To erase additional notes,
continue pressing pads. The Notes field will always display the
last pad pressed, and the total number of pads selected is dis-
played on the right side of the same line.
3. Press Soft key 1: <Do it>. When you press this soft key, all
notes assigned to the note number(s) you selected will be erased
throughout the track, after which the Play/Record screen will be
displayed.
4. Now, enter Overdub mode by holding OVERDUB and PLAY
START simultaneously and re-record that pad into your track.
(Unlike Record mode which erases existing notes as you record
new notes, Overdub mode merges the new notes into the existing
notes.)
To hear your new drum pattern, press STOP then PLAY START.

---

## Sequence Recording Example 2: A Multitrack Sequence
The following is a step-by-step example of recording a multitrack
sequence with a format of 4 bars of 4/4 time, containing the follow-
ing tracks:
Track 1: Drums
Track 2: Percussion
Track 3: Bass
Track 4: Piano
First, set up the instruments:
1. Using the connection diagram in the “Hooking Up Your System”
section (in the “Basics” chapter) as a guideline, connect the MIDI
Out connector of a MIDI keyboard to MIDI Input 1 of the
sequencer and connect MIDI Output A of the sequencer to a
multitimbral synthesizer that is set to play both bass and piano
sounds simultaneously. (Alternately, you could connect two
synthesizers in a daisy chain, with the MIDI thru connector of
the first synthesizer connecting to the MIDI input of the second.)
2. Set up the synthesizer(s) so that a bass sound plays from MIDI
channel 1A and a piano sound plays from MIDI channel 2A. If
you are using a single integrated keyboard, set Local Control on
your keyboard to OFF during this tutorial.
3. If no sounds are loaded into sound memory, load a program file
from one of the sound disks included with your sequencer. If you
don’t know how to do this, see the chapter “Saving To and Load-
ing From Disk”.
4. The Play/Record screen should be showing. If not, press MAIN
SCREEN.
5. The upper line of the screen should display Play/Record
(Record ready). If not, press either the RECORD or OVER-
DUB key once. This will make the current sequence ready for
recording.
Next, initialize the sequence to 4 bars of 4/4 time:
1. Move the cursor to the Seq field and select 2 (ENTER) or any
other sequence that is currently empty.
2. Press the ERASE key, then select SOFT KEY 2
(<Initialize>). The following screen will appear:

```
========== Initialize Sequence =========
Select sequence: 2-(unused)
===== General ===== ==== Track: 1 ====
Bars: 2 Sig: 4/ 4 Status:UNUSED
BPM:120.0 (SEQ) Type:DRUM Pgm:OFF
Loop:TO BAR 1 Chn:OFF & OFF
========================================
<Do it> <Track-> <Track+>
```

4. Enter 4 in the Bars field then press <Do it>. The Play/Record
screen will reappear, showing that the sequence has been initial-
ized to 4 bars of 4/4.
COMMENT: Whenever you select an empty sequence followed
by pressing either RECORD or OVERDUB, the sequence will
be initialized using the settings in this screen. Now that you
have changed these settings to 4 bars of 4/4, looped, when-
ever you now select an empty sequence in the Play/Record
screen and press either RECORD or OVERDUB, the se-
quence will be initialized instantly to 4 bars of 4/4, looped,
instead of the factory default of 2 bars of 4/4, looped. These
settings, as well as the contents of many other data fields in
the sequencer, are remembered when the power is turned off,
so this new default will remain in effect until changed.
Now, record the drums on track 1:
1. Move the cursor to the Trk field and select 1 (Enter) to make
track number 1 active.
2. Set the Type field to DRUM.
3. While holding RECORD, press PLAY START. The RECORD and
PLAY keys’ lights should go on, and the metronome should be
heard through the stereo outputs. The metronome will play on 1/
4-notes, with a louder sound at the start of each bar. Also, the
Now field will be changing constantly to reflect the current
position within the sequence.
4. Record the bass drum and snare drum parts by playing the pads
labeled with those names. Notice that when the sequence loops
back to bar 1, Record mode automatically changes to Overdub
mode so that the new part won’t get erased. Notice also that
every time the four-bar pattern loops back to the start, any
drums recorded on the last pass will be heard at the position they
were recorded, except that your notes will have been moved to
the nearest value specified in the Timing Correct screen (in this
case, 1/16-note).
5. Without stopping the sequence, record a 1/16-note hi-hat part by
simultaneously holding the TIMING CORRECT key and the
HIHAT CLOSED pad, varying the pressure on the pad as the
sequence plays. After four bars, release both the key and the pad.
Notice that closed hi-hats have now been recorded on all 1/16-
notes. This feature is called note repeat and is described further
in the “Timing Correct” section, later in this chapter. If at any
time you want to erase what you’ve recorded and start over, go
back to step 3.
If you accidentally played one or two wrong notes, you can erase
them without affecting any other notes by following these steps:
A) While still in Overdub mode, hold down the ERASE key.
B) Just before the wrong notes are about to play, hold that
drum’s pad down, then quickly release it as soon as the
wrong notes have passed.
C) Release the ERASE key. The wrong notes have now been
permanently erased from the sequence.
6. Press STOP.
Next, overdub the percussion part on track 2:
1. With the Play/Record screen showing, move the cursor to the Trk
field and select 2.
2. Set the Type field to DRUM.
3. Enter Record mode again by holding RECORD and pressing
PLAY START. You will hear the drum part you just recorded on
track 1. Don’t worry about erasing it: since track 2 is now the
active track, all recording and erasing occurs only on track 2.
4. Record the percussion part by playing pads assigned to percussion
instruments. (Try Pad Bank B.) Keep adding drums until your
percussion part is complete.
5. If any mistakes were made, use either of the two erase methods
described above.
Next, overdub the bass part on track 3:
1. With the Play/Record screen showing, move the cursor to the Trk
field and select 3 to make track 3 active.
2. Set the Type field to MIDI, indicating that this track will not
play the internal drum sounds.
3. Set the Chn field to 1A, indicating that track 3 will play through
MIDI channel 1 and MIDI output port A. The Chn field is actu-
ally two fields—move the cursor to the position indicated by the
underline below and select 1:
Chn:OFF becomes—> Chn: 1A
4. If you play the MIDI keyboard now, the synthesizer that is set to
receive on MIDI channel 1 should play a bass sound. If not, check
the previous steps and your MIDI hookup.
5. Press the COUNT IN key—the light will go on. This will cause
the metronome to play one bar before the sequence plays to cue
you to start playing. By default, the count in will only play before
you start recording or overdubbing but not before playing. This
can be changed by pressing the OTHER key and changing the
setting of the Count in field in the screen that appears.
6. Enter RECORD MODE by holding RECORD and pressing PLAY
START.
7. Once the COUNT IN bar has passed, record your bass part in
time to the drums and percussion parts.
8. Press the COUNT IN key again to turn it off.
9. If you make a mistake while recording, you can correct it by
punching in the new note:
A) Press the REWIND keys [<] or [<<] until the Now field
shows a location about one bar before the mistake.
B) Press PLAY (not PLAY START). The sequence will start
playing from the position shown in the Now field.
C) Just before the wrong note plays, press RECORD and
PLAY simultaneously to enter Record mode (in which
existing notes are erased while new notes are recorded)
then play the correct note. You can now either punch out
by pressing RECORD again or continue recording from
that point. Don’t worry: when the sequence loops back to
bar 1, it will automatically switch from Record to Over-
dub mode so that those notes in the earlier part of the
sequence won’t be erased.
Now, overdub the piano part on track 4:
1. Move the cursor to the Trk field and select 4 to make track 4 active.
2. Set the Type field to MIDI, indicating that this track will not
play the internal drum sounds.
3. Set the Chn field to 2A, indicating that track 4 will play through
MIDI channel 2 and MIDI output port A.
4. If you play the MIDI keyboard now, the synthesizer that is set to
receive on MIDI channel 2 and port A should play a piano sound.
If not, check the previous steps and your MIDI hookup.
5. Enter Record mode by holding RECORD and pressing PLAY
START.
6. Record your piano part in time to the drums, percussion and bass
parts.
7. Press STOP.

---

## The TIMING CORRECT Key: Correcting Timing Errors, Swing Timing
The sequencer corrects timing errors made as you are recording by
moving notes to the nearest perfect timing location. For example, if
the timing correct function is set to 1/16-notes, then all notes are
moved to the nearest perfect 1/16-note. The result is that all re-
corded notes play back as perfectly even 1/16-notes. It is also pos-
sible to correct the timing of notes after they have been recorded.
To inspect or change the timing correction settings, press TIMING
CORRECT while the sequencer is not playing. The following screen
will appear:

```
====== Timing Correct / Step Size ======
Note value:1/16 NOTE Swing%:50
Shift timing:LATER Shift amount: 0
========= Move Existing Notes ==========
Track: 1-(unused)
Ticks:001.01.00-001.01.00
Notes:ALL (Hit pads)
<Move existing>
```

This screen presents various parameters relevant to the timing
correct function. A description of each of the fields follows:
• The Note value field:
Timing correction works by moving your recorded notes to a preset
note timing value. This field is used to select that note value. The
options are:
1.1/8 NOTE: All notes are moved to the nearest 1/8-note
2.1/8 TRPLT: All notes are moved to the nearest 1/8-note
triplet
3.1/16 NOTE: All notes are moved to the nearest 1/16-note
4.1/16 TRPLT: All notes are moved to the nearest 1/16-
note triplet
5.1/32 NOTE: All notes are moved to the nearest 1/32-note
6. 1/32 TRPLT: All notes are moved to the nearest 1/32-
note triplet
7. OFF(1/384): No timing correction—in this setting, the
highest resolution of the sequencer is used—96 divisions
per 1/4-note.
This value also affects two other functions in the sequencer:
1. It sets the Note Repeat timing value, described later in
this chapter.
2. It sets the amount by which the current sequence position
will change when either the REWIND [<] or FAST
FORWARD [>] key is pressed.
• The Swing% field:
This field only appears if the Note Value field is set to either 1/16- or
1/8-notes. The swing feature is a variation of timing correction.
Whereas normal timing correction moves your notes to perfect 1/16-
or 1/8-note intervals, the swing feature moves your notes to swing-
timing intervals. The amount of swing is measured as a percentage
of time given to the first note in each pair of 1/16- or 1/8-notes. The
range of values is from 50% to 75%. For example:
• A swing setting of 50% gives perfectly even timing with no
swing effect; the first and second notes of each pair of 1/16-
or 1/8-notes have equal (50%) timing.
• A swing setting of 66% indicates a technically perfect
swing; the first note of each pair of 1/8 or 1/16 notes has a
timing value of twice that of the second note, giving the
effect of 1/16- or 1/8-note triplets where the middle note of
each triplet is silent.
• A swing setting of 75% is the highest swing setting; the
first note of each pair of 1/8 or 1/16 notes has a timing value
of three times that of the second note. This creates a very
exaggerated swing timing.
A very important use of the swing feature is to add a human rhythm
feel to the timing of your music. Here are a couple of useful settings
to experiment with:
• Note Value = 1/16, Swing = 54%, Tempo = 100 BPM:
While not enough swing for a true swing feel, this small
amount of swing timing removes the stiffness from perfect 1/
16-note timing and is especially useful on drum sequences
using 1/16-note hi-hats.
• Note Value = 1/16, Swing = 62%, Tempo = 100 BPM:
This creates an 1/16-note swing feel that could be described
as more relaxed than a perfect triplet swing (66%).
As with timing correction, swing moves your notes in real time as
they are recorded into the sequence, so your notes are instantly
played back with the specified shift. Also, as with timing correction,
this effect can be used on existing sequence data by using SOFT
KEY 1 (<Move existing>).

#### The Shift Timing and Shift Amount Fields

• The Shift timing and Shift amount fields:
These two fields work in conjunction with the Note value and
Swing% fields to move your notes to shifted timing locations. The
Shift timing field sets the direction of shift (EARLIER or
LATER) and the Shift amount field sets the amount of timing
shift in ticks (1/96 of a 1/4-note). For example, in order to compen-
sate for the slow attack time of a particular synthesizer, you might
set these two fields to EARLY, 1 tick. This would cause all new notes
to be recorded onto 1/16-notes but at 1 tick earlier than normal.
COMMENT: It is not possible for this function to shift the
timing of notes without also correcting their timing. This also
means that the range of shift depends on the current Note
value field’s setting. For example, if the Note value
field is set to 1/16-notes, the maximum shift amount is 11
ticks, or slightly less than 1/2 of one 1/16-note; if the Note
value field is set to 1/32 notes, the maximum shift amount
is 5 ticks, or slightly less than 1/2 of one 1/32 note; and if
the Note Value field is set to OFF(1/384), the Shift
amount is fixed at 0, meaning that no shift is possible since
timing correction is not being used. If you wish to shift the
timing of a track independently of the timing correction
function, use the Shift Timing function, accessed by pressing
the SEQ EDIT key.
COMMENT: If the Shift Timing function is set to shift
notes early and one or more notes exist at the start of the
sequence, these starting notes will be deleted when the
<Move existing> operation is performed, because
there is no space before the start of the sequence for them
to be moved to. To avoid this problem, insert a blank bar
before bar 1 of the sequence before performing the shift
operation, then be sure to include this extra bar within the
range of bars to be shifted. This way, the notes that would
have been lost will now be moved onto this newly inserted
bar.
• The Ticks fields:
These two fields are used to specify the region of the sequence that
will be altered when the <Move existing> soft key is pressed.
These are bar.beat.tick fields—the region starts at the location
entered in the leftmost field and ends one tick before the location
entered in the rightmost field.
• The Track field:
This field is only used in conjunction with the <Move existing>
soft key. It is used to specify the track number that is to be altered.
Entering a 0 indicates all tracks will be altered.
• The <Move existing> soft key:
Normally, the timing correct function operates in real time, correct-
ing notes before they are recorded into the sequence. It is also
possible to correct the timing (or add swing or shift the timing) of an
existing sequence. Pressing this soft key will cause the region of the
active sequence specified by the Ticks and Track fields to be
corrected according to the settings of the Note value, Swing%,
Shift timing and Shift amount fields.

The Note Repeat Feature
Another very useful feature of the TIMING CORRECT key is the
ability to automatically repeat either drum or keyboard notes at a
preset timing interval. This is useful in creating:

- Drum rolls
- Repeating-note drum patterns, such as 1/16-note hi-hat patterns
- Repeating keyboard notes, such as a repeated 1/16-note bass part

The Note Repeat feature is used in real time while recording or
playing. To use this feature, press and hold TIMING CORRECT
while in Play, Overdub, or Record mode. The top line of the Play/
Record screen will change to:

```
==== (Hold pads or keys to repeat) =====
```

If any drum pads (when the active track is a drum track) or keys
(when the active track is a MIDI track) are held while TIMING
CORRECT is being held, they will automatically be repeated at the
timing interval selected in the Note value field of the Timing
Correct screen. Furthermore, the velocity level of each repeating
note is set by the current pressure applied to the drum pad or key
being played (if your MIDI keyboard has channel pressure capabil-
ity). To demonstrate this effect:
1. Set up a sequence for recording, select a drum track to record,
and initiate recording.
2. While holding TIMING CORRECT, also hold the drum pad
assigned to the closed hi-hat, varying the pressure as you hold it.
You should hear repeating 1/16-note hi-hats.
3. Press STOP to stop playing.
4. Press TIMING CORRECT and select 1/32 TRPLT in the Note
field.
5. Press MAIN SCREEN to return to the Play/Record screen.
6. Enter Overdub mode.
7. While holding TIMING CORRECT, also hold the pad assigned to
snare drum, varying the pressure as you hold it. You should hear
a snare drum roll with varying dynamics.
This same procedure can be used in exactly the same way when
recording keyboard sequences. In this case, hold TIMING COR-
RECT while holding one or more keys on the MIDI keyboard. In
order to use the varying pressure technique, you will need to use a
keyboard that sends channel pressure messages.

---

## Tempo and the TEMPO/SYNC Key

Many of the functions in the sequencer are associated with control-
ling the playing tempo. First, there is the Tempo field in the Play/
Record screen (shown below in bold):

```
============== Play/Record =============
Seq: 1-(unused) BPM:120.0 120.0 120.0 120.0 120.0 (SEQ)
Sig: 4/ 4 Bars: 0 Loop:TO BAR 1
============== Track Data ==============
Trk: 1-(unused) Type:DRUM On:YES
Chn:OFF-(off) & OFF Vel%:100 Pgm:OFF
===== Now:001.01.00 (00:00:00:00) ======
<Tk on/off> <Solo=OFF> <Track-> <Track+>
```

To change the tempo at any time while playing or recording se-
quences, move the cursor to the Tempo field and change it with the
data knob or the numeric keypad.

### The Tempo Screen

To display the Tempo screen, press the TEMPO/SYNC key:

```
================ Tempo =================
Tempo:120.0 Tempo source:SEQUENCE
============= Display mode =============
BPM/FPB:BPM Frames:30 DROP
============== Tap Tempo ===============
Tap averaging:3
========================================
<SyncScreen ><TempoChanges>
```

This screen presents most of the parameters that are associated
with tempo. A detailed description of the individual screen fields and
soft keys follows:
• The Tempo field:
This is the active playing tempo. It is either the sequence’s assigned
tempo or the master tempo, depending on the setting of the Tempo
source field. This has the same function as the Active Tempo field
in the Play/Record screen except that this field doesn’t display
tempo changes.
• The Tempo source field:
This field has the same function as the Tempo Source field in the
Play/Record screen: It determines whether the sequence’s
tempo or the master tempo is currently active. It is a choice field
with two options:
1. SEQUENCE: Within each sequence is a unique tempo
setting. If this option is selected, this unique sequence
tempo is used. In this case, whenever the active sequence
number is changed, the newly selected sequence’s tempo
immediately becomes active. When playing sequences,
this is useful if you want each newly selected sequence to
play at its own preset tempo. Only the sequence’s tempo
is saved to disk when a sequence is saved.
2. MASTER: The master tempo is a single tempo setting that
applies to all sequences and songs. When playing se-
quences this is useful if you want each newly selected
sequence to always play at the same tempo.
• Tempo Display Mode field (BPM/FPB:BPM BPM BPM BPM BPM):
This field has the same function as the Tempo Display Mode field in
the Play/Record screen: it determines whether the active tempo is
displayed as Beats Per Minute or Frames Per Beat. It is a choice
field with two options:
1. BPM: The tempo is displayed in Beats Per Minute, with
the digit to the right of the decimal point indicating
tenths of a beat. This is the most common format used to
specify a tempo setting. In this mode, the range of tempo
settings in the sequencer is from 30 BPM to 300 BPM.
Beats Per Minute is also sometimes referred to as metro-
nome marking, or MM.
2. FPB: This is another way of specifying tempo settings and
is often used in the making of music for film or video
soundtracks, because the tempo is referenced to the
number of film or video frames that pass for every beat of
music. Frames Per Beat is also sometimes referred to as
click. If the FPB setting is in use, the digit to the right of
the decimal point in any of the numeric tempo settings
indicates eighths (1/8 of a frame). The range is from 0 to
7. There are four different types of FPB tempo, described
in the Frames field below.
• The Frames field:
This field selects one of four Frames Per Second standards, used to
calculate the current FPB (frames per beat) setting. It also sets the
frame rate (and therefore affects the tempo) for received SMPTE
sync or MIDI Time Code. The four options are:
30 (30 frames per second, non-drop):
This is the most common frame rate for music production in
the United States. It was also the standard for black and
white television in the U.S. Using this mode, the tempo
range of the sequencer is from 60.0 to 6.0 FPB.
29.97 DROP (29.97 frames per second, drop frame):
This is the standard for NTSC color television in the United
States. Using this mode, the tempo range of the sequencer is
from 59.7 to 6.0 FPB.
COMMENT: In the MPC60 version 2 software, this
selection was erroneously called 30DROP, although it
was actually 29.97 frames per second drop frame
time code. Sorry.
25 (25 frames per second):
This is the standard for European television (PAL /SECAM
standard). Using this mode, the tempo range of the
sequencer is from 50.0 to 5.0 FPB.
24 (24 frames per second):
This is the standard for film. However, since film is usually
transferred to video for scoring, the composer still works
with the video standard frame rates. Using this mode, the
tempo range of the sequencer is from 48.0 to 5.0 FPB.
• The Tap averaging field
This parameter is used in conjunction with the TAP TEMPO key.
The TAP TEMPO key is used for quick setting of the playing tempo
by repeatedly tapping 1/4-notes on the key at the desired tempo.
(This is described further in the section “The Tap Tempo key.”)
Repeated taps are averaged to help reduce timing errors; this field
sets the number of taps that must be played successively before the
tempo is recalculated. The options are:
2 taps:
The tempo is recalculated after only two taps. This should
be used only if your timing is very good, or if you want to set
the new tempo roughly.
3 taps:
Initially, the tempo is recalculated after the first two taps. If
you continue to tap successive 1/4-notes, the tempo is
continuously recalculated by averaging the last three
successive tap intervals. This is a good average setting.
4 taps:
Initially, the tempo is recalculated after the first two taps. If
you tap a third time, the tempo will be recalculated using an
average of the three taps. If you continue to tap successive 1/
4-notes, the tempo is continuously recalculated on each
successive tap by averaging the last four successive tap
intervals. This is very useful if your timing is not very
accurate, because it smoothes out your timing errors.
• The <SyncScreen> soft key :
This screen is described in the chapter entitled “Syncing to Tape and
Other Devices.”
• The <TempoChanges> soft key:
The function of this soft key is described in the following section.
Mid-Sequence Tempo Changes
This feature allows the tempo to change automatically at preset
locations within a sequence. To insert tempo changes into the active
sequence or to view existing tempo changes, press the TEMPO/
SYNC key, then press the <TempoChanges> soft key. The follow-
ing screen will appear:
====== Mid-sequence tempo changes ======
Tempo changes:ON
Location for inserted change:001.01.00
Change#: Bar#: %Change: =Tempo:
2 002.03.00 150.00 180.0 BPM
========================================
<Insert new> <Delete> <Previous> <Next>
In the center of the screen is a group of fields, labeled Change#,
Bar#, %Change and =Tempo. In this case, the labels are located
directly above the actual data fields. These four fields work together
to allow you to view or edit any tempo changes that exist in the
sequence.
There can be many tempo changes in the sequence. These four fields
show one of these changes at a time. The Change# field shows the
number of the currently displayed tempo change within the list of
changes; the other fields show the contents of that tempo change.
For example, the above screen example shows that tempo change
number 2 will occur at bar 2, beat 3, and will change the tempo by
150% to 180 beats per minute.
The following is a description of each of these four fields:
• The Change# field:
This field displays the number of the tempo change cur-
rently displayed. There can be many tempo changes within
the sequence, but only one can be viewed at a time. By
changing this number, each of the existing tempo changes
can be viewed. The <Previous> and <Next> soft keys
can also be used to decrement or increment this field.
• The Bar# field:
This field shows the location within the sequence where the
currently displayed tempo change will occur. This is a
bar.beat.tick field.
• The %Change field:
This field shows, as a percentage of the main starting tempo
(either MASTER or SEQUENCE), the amount of tempo
change that the currently displayed tempo will produce.
Tempo changes are always specified as a percentage of the
main starting tempo setting (not the previous tempo
change), regardless of whether the SEQUENCE or MASTER
tempo setting is currently active. This way, all tempo
changes are automatically re-scaled when the main tempo
setting (either SEQUENCE or MASTER) is changed.
• The =Tempo field:
This field displays the actual tempo number that will play
once the tempo change is active. This number is automati-
cally computed from the displayed percentage of change
multiplied by the main playing tempo (either MASTER or
SEQUENCE).
To view the entire list of tempo changes, simply modify the
Change# field and notice the different settings of the other three
fields as you change it. Even if no changes have been entered, every
sequence has one change—to 100% at bar 1. This is because the
current tempo setting is always returned to when the sequence
plays bar 1, whether it does so by playing from the start or by
looping back to the start.
To insert a new tempo change, enter the location within the se-
quence where you want the change to occur into the Location
for inserted change field, which is a bar.beat.tick field.
Then press the <Insert new> soft key. Immediately, a new
tempo change will be inserted into the list, displayed on the screen
with a default value in the %Change field of 100%. You must now
enter a percentage of the main starting tempo. As you enter the
percentage, the =Tempo field will show the actual tempo. For
example, to insert a tempo change to 60 BPM at bar 5 from a main
starting tempo of 120 BPM, you must insert a tempo change with a
value of 50% at bar 5 (120 BPM X 50% = 60 BPM).
To delete the currently displayed tempo change, press the
<Delete> soft key.
The field at the top of the screen, Tempo changes, is a choice
field with two options: ON and OFF. If set to ON, tempo changes are
used; if set to OFF, all tempo changes within the sequence are
ignored.

The TAP TEMPO Key
The TAP TEMPO key allows the tempo to be set quickly by tapping
two beats (1/4-notes) on the TAP TEMPO key. After two taps, the
sequencer automatically assumes the two taps to be 1/4-notes and
recalculates a new tempo to match those 1/4-notes.
For example, to quickly change to a tempo of 80 BPM, tap two 1/4-
notes at a tempo of approximately 80 BPM on the TAP TEMPO key.
After the second tap, the new tempo will appear in the Active Tempo
field of the Play/Record screen. This can also be done while the
sequence is playing.
Normally, only two taps are required before the sequencer recalcu-
lates the new tempo. However, it is possible to set this feature so
that it recalculates the tempo by averaging the last three (or four)
successive tap intervals. This is set in the Tap averaging field,
located in the Tempo screen. More information about using the TAP
TEMPO key is contained in the “Tempo and the TEMPO/SYNC Key”
section of the manual, earlier in this chapter.

---

## The WAIT FOR and COUNT IN Keys

These two keys make the process of real-time sequence recording
easier.
The WAIT FOR KEY key
This function is useful in the recording of keyboard sequences when
your keyboard is not located close to the sequencer. If Play, Record
or Overdub mode is entered while the Wait For Key function is on,
the sequence will not begin to play until a key is played on the MIDI
keyboard. This acts as a remote switch to start the sequence play-
ing. Note that the first key that is played to start the sequence is
NOT recorded into the sequence—it only starts the sequence. All
keys played after recording has been initiated are recorded into the
sequence.
To turn Wait For Key mode on, press the WAIT FOR KEY key once;
the light goes on to indicate it has been activated. To turn the mode
off, press the WAIT FOR KEY key again and the light will go off. If
set to ON, it will automatically go OFF after it has been used once
(for playback, recording, or overdubbing a sequence). You must turn
it on again each time you want to use it.
The COUNT IN key
If the Count In function is on, one bar of metronome clicks will
precede the playing of the sequence or song whenever you initiate
playback of a sequence or song. The clicks provide a tempo guide to
prepare you to record or play along with the sequence.
Press COUNT IN to turn the function on and again to turn it off.
While on, the light above the key is lit.
It is possible to select a mode in which the count in only occurs
before recording and not before playing. To select this mode and to
adjust other metronome parameters, press the OTHER key. These
features are explained in the “OTHER Key” section, later in this
chapter.
COMMENT: While the Count In bar is playing, keys played
on the MIDI keyboard will not be output through MIDI (via
the sequencer ‘s Soft Thru function) until the Count In bar
has finished. For example, if you were to play a chord during
the count in bar, the chord would not sound until bar 1
started playing. This is normal operation and serves as a
reminder that no notes can be recorded during the count in
bar, and that any notes played during that time will be held
and recorded at the start of the sequence.
---

## ### The ERASE Key

The ERASE key provides three main functions:
• Erasing notes in real time while in Overdub mode
• Erasing notes or other events while stopped
• Initializing or deleting sequences
Erasing Notes in Real Time While in Overdub Mode
If the ERASE key is pressed and held while in Overdub mode, the
top line of the Play/Record screen changes to the following for as
long as ERASE is held:
==== (Hold pads or notes to erase) =====
If during this time you hold a drum pad (if the active track is a
Drum track) or hold a key on the MIDI keyboard (if the active track
is a MIDI track), any notes assigned to that pad or key in the
selected track will be erased.
Erasing Notes or Other Events While Stopped
While not playing, the sequencer allows the erasure of specific
events from any region within a sequence, on one or all tracks. This
is done using the ERASE key.
If the ERASE key is pressed while the sequencer is not playing, the
Erase screen appears:

```
================= Erase ================
Seqnc: 1-SEQ01
Track: 1-TRK01 (0 = all)
Ticks:001.01.00-003.01.00
Erase:ALL EVENTS
Notes: 0(C.-2)-127(G.8 ) (Press keys)
========================================
<Do it> <Initialize><Delete><Delete All>
```

To erase the notes, enter the appropriate data into each of the data
fields, then press the <Do it> soft key. Each of the screen fields
and soft keys is described below:

#### The Seqnc (sequence) field

• The Seqnc (sequence) field:
In this field, enter the sequence number from which the data will be
erased. The sequence name is shown to the right for convenience.
• The Track field:
This field specifies the track from which the data will be erased. The
active track is automatically inserted here. To erase all tracks at
once, enter a 0 here. In that case, the Notes field will be forced to
ALL because it is not possible to select specific notes for erasure
when erasing all tracks.
• The Ticks fields:
These two fields are used to set the region to be erased, starting
with the location specified in the leftmost field, through one clock
before the location specified in the rightmost field. They are both
bar.beat.tick fields, allowing you to set the region to be erased in
increments as small as one tick.
• The Erase field:
This field allows you to select which types of events will be erased. It
is a choice field with three options:
1. ALL EVENTS: If this option is selected, all possible MIDI
event types will be erased.
2. ONLY ERASE: If this option is selected, only one event
type will be erased, and the type of event to be erased will
appear in a choice field directly to the right on the same
line. In this rightmost field, all event types are listed,
including all 128 MIDI controllers.
3. ALL EXCEPT: If this option is selected, all MIDI event
types EXCEPT one specific type will be erased; the event
type that will NOT be erased will appear in a choice field
directly to the right on the same line. In this rightmost
field, all event types are listed, including all 128 MIDI
controllers.
• The Notes field:
This field determines which notes will be erased. It appears in one
of two ways depending on whether the selected track is a Drum
track or a MIDI track:
1. If the source track is a MIDI track, two numeric fields—
used to set the lowest and highest notes to erase within
the MIDI keyboard’s range—will appear as above. Each
of these numeric fields is editable and has a range of 0 to
127; the equivalent note name (C-2 to G8) is shown to the
right of each field. Alternately, these fields can be set by
pressing two notes on the MIDI input device’s keyboard.
The fields will automatically be set to the lowest and
highest keys pressed.
2. If the source track is a Drum track, this field is used to
select specific MIDI note numbers for erasure, but
cannot be accessed by the cursor—it can only be
changed by pressing pads or by receiving external
MIDI notes. When the screen is first displayed, it
contains the word ALL (erase all notes) and the text

(Hit pads) to the right. When a pad is pressed, its
currently assigned note number will appear in the field,
followed by the pad number and currently assigned sound
name. On the right side of the line is the text (1 pad)
indicating that 1 pad is selected for erasure:
Notes:36/A02-SNARE_DRUM (1 pad)
If another pad is then pressed, its note number, pad
number, and assigned sound are displayed instead, and
the text to the right displays (2 pads). This continues
until the user has selected all of the pads he or she
intends to erase.
• The <Do it> soft key:
Pressing this soft key performs the erasure specified by the data in
the screen fields. After the erasure has been performed, the Play/
Record screen is redisplayed.
• The <Initialize> soft key:
This soft key is used to erase and initialize the entire sequence to
specific values. Please see the following section, “Initializing a
Sequence,” for an explanation of this feature.
• The <Delete> soft key:
This soft key is used to delete the entire sequence, which erases all
data and sets the sequence to the same unused state as when power
is first turned on. When a sequence is deleted, it uses the least
amount of memory, less than if it is initialized. When SOFT KEY 3
(<Delete>) is pressed, the following screen appears:

```
============ Delete Sequence ==========
Sequence: 23-Sequence_name
(This will set sequence to unused state
with no contents.)
========================================
<Do it>
```

To delete the sequence, enter the desired sequence number and
press <Do it>.

#### The <Delete all> Soft Key

• The <Delete all> soft key:
This soft key is used to delete all 99 sequences, setting them to the
same state as when power is first turned on (maximum available
sequence memory). When <Delete all> is pressed, the
following screen appears:

```
========= Delete All Sequences =========
Pressing <Do it> will erase all
sequences and set them to unused state
as when power is turned on!!!!
========================================
<Do it>
```

To delete all sequences, press <Do it>.

### Initializing a Sequence
To erase a sequence and initialize it to preset values, press the
ERASE key, followed by SOFT KEY 2 (<Initialize>). The
following screen will appear:

========== Initialize Sequence =========
Select sequence: 1-(unused)
===== General ===== ==== Track: 1 ====
Bars: 2 Sig: 4/ 4 Status:UNUSED
BPM:120.0 Type:DRUM Pgm:OFF
Loop:TO BAR 1 Chn:OFF & OFF
========================================
<Do it> <Track-> <Track+>

The fields and soft keys are:
• The Select sequence field:
This field is used to enter the number of the sequence that is to be
initialized. The selected sequence’s name is shown for convenience.
The “General” section:
• The Bars field:
In this field enter the number of bars for the initialized sequence.
• The Sig (time signature) field:
In this field enter the time signature for the initialized sequence. It
is actually two fields, one for the upper and one for the lower parts
of the time signature.
• The BPM field:
In this field enter the tempo to which you want the sequence to be
initialized. To view the tempo in frames per beat, move the cursor to
the word BPM and use the data entry control to change it to FPB,
just as in the Play/Record screen.

• The Loop field:
In this field enter the loop status (OFF or TO BAR) and the loop bar
number, if TO BAR is selected, for the initialized sequence.
The “Track” section
• The Track field:
Any or all of the sequence’s tracks can be initialized. To enter the
settings for each track, first select the track number in this field,
then enter the initialization data for that track in the fields below.
The contents of the five fields in this section apply only to the track
(1 of 99) that is selected in this field.
• The Status field:
This is a choice field with two options:
1. UNUSED: The track number displayed in the Track field
will not be initialized. Instead, it will be set to an unused
state (as when power is turned on), which requires the
least amount of memory. However, if this track is later
recorded into, it will immediately be initialized to default
values.
2. IN USE: The track number displayed in the Track field
will be initialized to the values entered in the Type, Pgm
and Chn fields.
• The Type field:
The Type field for the selected track will be initialized to the option
selected in this field (DRUM or MIDI).
• The Pgm field:
The Pgm field for the selected track will be initialized to the option
selected in this field (1-128 or OFF).
• The Chn field:
In this field enter the output MIDI channel (1-16 or OFF) and port
(A-D) to which the selected track will be initialized, using the same
data entry method as in the Chn field in the Play/Record screen. To
the right of this field is another field for the auxiliary MIDI output
channel assignment.
• The <Do it> soft key:
After values for all the fields have been entered, press this soft key
to initialize the sequence.

### The SEQ EDIT Key
The SEQ EDIT key provides access to many features related to
sequence editing. Pressing it will display the following menu screen:

```
============= Edit Sequence ============
1)View/chng T sig 6)Copy events
2)Chng track order 7)Copy a sequence
3)Insert blank bars 8)Shift timing
4)Delete bars 9)Edit note data
5)Copy bars
========================================
```

Select option:
Pressing a single number key causes the screen for the selected
function to appear. These functions are described below:
Viewing and Changing Time Signature
This feature displays the time signature and number of bars in the
active sequence as well as any time signature changes. Press 1
(View/chng T sig) from the SEQ EDIT key menu and the
following screen will be displayed:

========== View Time Signature =========
Bar 1 - 2: 4/ 4
========================================
<<<Change TSig>

This screen displays all time signature changes within the active
sequence, and the number of bars associated with each change. If no
time signature changes exist, the existing single time signature and
the total number of bars in the sequence will be displayed. Space is
given for ten time signature changes, with two changes per line. If
more exist, the <soft key is used to view more pages of
changes, and the <soft key is used to display earlier
pages.

Changing the time signature of a single bar
To change the time signature of a specific bar, press <Change
Tsig>. The following screen will appear:

======== Change Time Signature =========
Change the time signature of bar: 1
from 4/ 4 to 4/ 4.
(If the new time sig is shorter, the end
of the bar is truncated; if longer,
blank space is added to the end.)
========================================
<Do it>

This function allows you to change the length of a particular bar
within a sequence by changing its time signature. It works like this:
if the time signature you change to is shorter than the existing one,
the unused end of the bar is truncated. For example, if you need to
remove one 1/8-note from the end of a 4/4 bar, you would change its
time signature to 7/8. If the new time signature is longer than the
existing one, a small amount of blank space will be added onto the
end of the bar.
To change the time signature of a bar, first select the bar number to
be changed in the top line. The existing time signature for that bar
will be displayed in the from field in the second line. Next, enter
the time signature you wish to change to in the to fields (2 parts) in
the second line. To perform the change, press the <Do it> soft key.
Rearranging the Track Order
This feature rearranges the track order by removing one track and
inserting it before another, causing all tracks in between to be re-
numbered. Multiple operations may be required to put the tracks in
the desired order. Select 2 (Chng track order) from the SEQ
EDIT key menu and the following screen will appear:
========== Change Track Order ==========
Sequence: 1-Seqnc_name
Place track: 1-Track_name
Before track: 2-Track_name
(Tracks in between will be renumbered.)
========================================
<Do it>

To rearrange tracks, first enter the desired sequence number. Then
enter the track number to be moved in the Place track field. In
the Before track field, enter the number of the track that the
moved track will be inserted before. Press <Do it> to execute the
move.
Inserting Blank Bars Into a Sequence
This feature inserts a specified number of blank bars into the
current sequence. Select option 3 (Insert blank bars) from
the SEQ EDIT key menu, and the following screen will appear:

========== Insert Blank Bars ===========
Sequence:12-Sequence_name
Number of bars: 4
Time signature: 4/ 4
Insert before bar: 4
========================================
<Do it>

The fields and soft key are:
• The Sequence field:
This is the sequence into which the bars will be inserted. The
sequence’s name is shown to the right.
• The Number of bars field:
This is the number of blank bars to be inserted.
• The Time signature field:
This is the time signature of the bars to be inserted. This is actually
two fields—one for each part of the time signature. The range of the
first part is from 1 to 31; the second part is a choice field with four
selections: 4, 8, 16, and 32.
• The Insert before bar field:
This field specifies the bar number before which the new bars will
be inserted. To insert bars after the end of the sequence, enter a
number one higher than that of the last bar in the sequence.
• The <Do it> soft key:
Pressing this soft key performs the insertion according to the above-
displayed parameters.
COMMENT: If the sequence is set to loop to an earlier bar (in
the time signature/ending status screen) and the new bars
are inserted before the loop bar, the bar number specified in

the Loop field will automatically be increased to compensate
for the insertion.
Deleting Bars From a Sequence
This function allows you to delete a specified number of bars from
the active sequence. To use this function, select option 4 (Delete
bars) from the SEQ EDIT key menu. The following screen will be
displayed:

=========== Delete Bars ============
Sequence:12-Sequence_name___
First bar: 1 Last bar: 2
========================================
<Do it>

The on-screen fields and soft keys are:
• The Sequence field:
This is the sequence from which the bars will be deleted. The
sequence’s name is shown to the right.
• The First bar field:
This is the first bar to be deleted.
• The Last bar field:
This is the last bar to be deleted.
COMMENT: For those of you familiar with the MPC60
version 2 operating software, this field has a different func-
tion than the To bar field in the MPC60’s Delete Bars
function. This field contains the last bar of the range of bars
to be deleted, whereas the MPC60’s To Bar field contained
the first bar number after the region to be deleted.
• The <Do it> soft key:
Pressing this soft key performs the specified deletion.
COMMENT: If the sequence is set to loop to an earlier bar (in
the Play/Record screen) and the deleted bars are before the
loop point, the bar number specified in the Loop field will
automatically be decreased to compensate for the deletion.

Copying Bars (All Tracks)
This function allows you to copy a specified range of bars (across all
tracks) from one sequence and insert the copied data at any point
within the same sequence or any other sequence. In this mode of
copying, the overall length of the destination sequence will always
be increased. To use this function, select option 5 (Copy bars)
from the SEQ EDIT key menu. The following screen will appear:

============ Copy Bars From ============
Seq:12-Sequence_name
First bar: 1 Last bar: 2
============= Copy Bars To =============
Seq:12-Sequence_name Before bar: 1
Copies: 1
========================================
<Do it>

The fields and soft key are described below:
• The Seq field (in the Copy Bars From section):
This field is used to specify the sequence number to be copied from.
• The First bar and Last bar fields:
These fields set the range of bars to be copied. First first bar in the range that is to be copied, and Last last bar to be copied.
bar sets the
bar sets the
COMMENT: For those of you familiar with the MPC60
version 2 operating software, this field has a different func-
tion than the To bar field in the MPC60’s Copy Bars
function. This field contains the last bar of the range of bars
to be copied, whereas the MPC60’s To Bar field contained
the first bar number after the region to be copied.
• The Seq field (in the Copy Bars To section):
This field is used to specify the sequence number to be copied to.
• The Before bar field:
This field specifies the bar number before which the copied data will
be inserted. To insert the bars at the end of the sequence, enter a
number one higher than that of the last bar in the sequence.
• The Copies field:
This field specifies how many repetitions of the source data will be
inserted into the destination sequence.
• The <Do it> soft key:
Pressing this soft key executes the copy according to the entered
parameters.

COMMENT: If the sequence is set to loop to an earlier bar (in
the Play/Record screen) and the copied bars are inserted
before the loop bar, the bar number specified in the Loop
field will automatically be increased to compensate for the
insertion.
COMMENT : When copying from one sequence to another, be
careful to copy MIDI track data only to MIDI tracks and
Drum track data only to Drum tracks. Otherwise, keyboard
notes can cause drum sounds to play or vice versa.
Copying Events
This function permits the copying of all events within a specified
region of a single track to a different point in the same or another
track in the same or another sequence. In this function, only the
events from the source track are copied—no time signature or tempo
data are copied. Unlike the Copy Bars function, which inserts the
copied data into the sequence, thus increasing its overall length,
this copy function either replaces the existing events or merges the
copied data with existing events, without adding additional bars.
Therefore, in this function, the track’s overall length is unchanged
after the copy has been executed.
To use this function, select option 6 (Copy EDIT key menu. The following screen will be displayed:
events) from the SEQ
=========== Copy Events From ===========
Sequence: 1 Track: 1-Track_name
Ticks:001.01.00-001.01.00
Notes:ALL (Hit pads)
============ Copy Events To ============
Sequence: 1 Track: 1-Track_name
Mode:REPLACE Copies: 3 Start:001.01.00
<Do it>
A description of the fields and soft key follows:
• The Sequence field (in the Copy Events From section):
This is the sequence from which the data will be copied.
• The Track field (in the Copy Events From section):
This is the track from which the data will be copied. Enter a 0 here
to copy all tracks at once. If you do this, the lower Track field (in
the Copy Events To section) will be forced to 0 also, because the
destination must also be all tracks.
• The Ticks fields:
These two fields are used to set the region of the track that will be
copied from, starting at the tick specified in the leftmost field and
including all data up to (but not including) the tick specified in the

rightmost field. These are bar.beat.tick fields, enabling you to
specify the region in units as small as one tick.
• The Notes field:
This field determines which notes will be copied. It appears in one of
two ways depending on whether the selected track is a Drum track
or a MIDI track:
1. If the source track is a Drum track, this field is used to
select the specific drum notes, represented as MIDI note
numbers, that are to be copied. It cannot be accessed with
the cursor; notes can only be entered by pressing pads or
via the reception of external MIDI notes. When the
screen is first displayed, it contains the word ALL (copy
all notes) and the text (Hit pads) to the right. When
a pad is pressed, the pad’s currently assigned note
number appears in the field, followed by the pad number
and currently assigned sound name. On the right side of
the line is the text ( 1 pad ) indicating that 1 pad is
selected for copying:
Notes:36/A02-SNARE_DRUM ( 1 pad )
If another pad is pressed, its note number, pad number,
and assigned sound are displayed instead, and the text to
the right displays ( 2 pads). This continues until the
user has selected all of the pads he or she intends to copy.
2. If the source track is a MIDI track, two numeric fields—
used to set the lowest and highest notes of the note range
that is to be erased—will appear. Each of these numeric
fields is editable via the cursor and has a range of 0 to
127; the equivalent note name (C-2 to G8) is shown to the
right of each field. Alternately, these fields can be set by
pressing two notes on the MIDI input device’s keyboard.
The fields will automatically be set to the lowest and
highest keys pressed.
• The Sequence field (in the Copy Events To section):
This is the sequence into which the data will be copied.
• The Track field (in the Copy Events To section):
This is the track to be copied to. If this field can’t be changed from
0—(all tracks), then the upper Track field (in the Copy
Events From section) must have been set to 0, indicating that all
tracks will be copied.
• The Mode field:
This is a choice field with two options:
1. REPLACE:
In this mode, all existing events in the destination track
are overwritten by the newly copied data.

2. MERGE:
In this mode, the copied data are merged, or added, to the
existing events.
• The Copies field:
This field specifies the number of repetitions of the copied data that
will be added to the new sequence.
• The Start field:
The copied data can be added into the destination sequence and
track starting at any location. This field specifies the start location
where the copied data will be placed. This is a bar.beat.tick field,
allowing the copied data to be placed starting at any location, in
increments as small as one tick.
• The <Do fields.
it> soft key:
Pressing this soft key performs the copy as specified in the above
COMMENT : Be careful to copy MIDI track data only to
MIDI tracks and Drum track data only to Drum tracks.
Otherwise, keyboard notes can cause drum sounds to play or
vice versa.
Copying an Entire Sequence to Another
This function is useful if you want to make a perfect copy of a
sequence, including all parameters, to another sequence number,
replacing all data and parameters previously contained in the
destination sequence. To use this function, select option 7 (Copy a
sequence) from the SEQ EDIT key menu. The following screen
will appear:
===== Copy One Sequence To Another =====
Copy contents of seq: 1-Sequence_name
Over contents of seq: 2-Sequence_name
========================================
<Do it>
A description of the screen fields and soft keys follows:
• The Copy contents of seq field:
This specifies the sequence to be copied from.

• The Over contents of seq field:
This specifies the sequence whose contents will be replaced by the
contents of the above specified sequence number. The lowest-
numbered empty sequence is automatically inserted here when this
screen is entered.
• The <Do it> soft key:
Pressing this soft key performs the above specified copy.
Shifting the Timing of Many Notes
This feature shifts a group of notes within a single track forward or
backward in time. To use this feature, select 8 (Shift timing)
from the SEQ EDIT key menu. The following screen will appear:

============= Shift Timing =============
Seqnc: 1-Sequence_name Dir:EARLIER
Track: 1-Track_name Amount: 0
Ticks:001.01.00-001.01.00
Notes: 0(C.-2)-127(G.8 ) (Press keys)
========================================
<Do it>

The fields and soft keys are:
• The Seqnc field:
This specifies the sequence to be shifted.
• The Track field:
This specifies the track to be shifted. Only one track can be shifted
at a time.
• The Ticks fields:
These two bar.beat.tick fields are used to determine the region
within the track that will be shifted. The leftmost field sets the start
point of the region and the rightmost field holds the location that is
one tick after the region to be shifted.
• The Notes field:
This field determines which notes will be shifted. It appears in one
of two ways depending on whether the selected track is a drum or
MIDI track:
1. If the source track is a MIDI track, two numeric fields—
used to set the lowest and highest notes of the note range
that is to be shifted—appear as above. Each of these
numeric fields is editable via the cursor, and has a range

of 0 to 127; the equivalent note name (C-2 to G8) is shown
to the right of each field. Alternately, these fields can be
set by pressing two notes on the MIDI input device’s
keyboard. The fields will automatically be set to the
lowest and highest keys pressed.
2. If the source track is a Drum track, this field is used to
select specific drum notes, represented as MIDI note
numbers, that are to be copied. It cannot be accessed with
the cursor; notes can only be entered by pressing pads or
via the reception of external MIDI notes. When the
screen is first displayed, it contains the word ALL (shift
all notes) and the text (Hit pads) to the right. When
a pad is pressed, the pad’s currently assigned note
number appears in the field, followed by the pad number
and currently assigned sound name. On the right side of
the line is the text ( 1 pad ) indicating that one pad
is selected for shifting:
Notes:36/A02-SNARE_DRUM ( 1 pad )
If another pad is then pressed, its note number, pad
number, and assigned sound are displayed instead, and
the text to the right displays ( 2 pads). This contin-
ues until the user has selected all of the pads he or she
intends to shift.
• The Dir (direction) field:
This choice field is used to determine the direction of shift and has
two options: EARLIER and LATER.
• The Amount field:
This field is used to determine the amount of shift in ticks.
• The <Do fields.
it> soft key:
Pressing this soft key performs the shift specified in the above
Global Editing of Note Event Data
If option 9 (Edit note data) is selected from the SEQ EDIT key
menu, the following menu, which contains three choices for editing
note data, appears:

============ Edit Note Data ============
1.Edit velocity/duration
2.Edit note number assignment
3.Edit note variation data
========================================

Select option:
These options are described in the three sections below.
Editing Note Velocity or Duration Data
To edit the velocity or duration data of a group of notes in one
operation, select 1 from the Edit Note Data menu. The following
screen will appear:

======== Edit Velocity/Duration ========
Seqnc: 1-Seqnc_name Edit:VELOCITY
Track: 1-Track_name Do:ADD VALUE
Ticks:001.01.00-001.01.00 Value:120
Notes: 0(C.-2)-127(G.8 ) (Press keys)
========================================
<Do it>

The fields and soft keys are:
• The Seqnc field:
This specifies the sequence to be edited.
• The Track field:
This specifies the track to be edited. Only one track can be edited at
a time.
• The Ticks fields:
These two bar.beat.tick fields are used to determine the region
within the track that will be edited. The leftmost field sets the start
of the region and the rightmost field holds a location one tick after
the region to be edited.
• The Notes field:
This field determines which notes will be edited. As shown above, it
appears in one of two ways depending on whether the selected track
is a Drum or MIDI track:
1. If the source track is a MIDI track, two numeric fields—
used to set the lowest and highest notes of the note range
that is selected for editing—appear as above. Each of
these numeric fields is editable via the cursor, and has a

range of 0 to 127; the equivalent note name (C-2 to G8) is
shown to the right of each field. Alternately, these fields
can be set by pressing two notes on the MIDI input
device’s keyboard. The fields will automatically be set to
the lowest and highest keys pressed.
2. If the source track is a Drum track, this field is used to
select specific drum notes, represented by MIDI note
numbers, that are to be edited. This field cannot be
accessed by the cursor—it can only be changed by press-
ing pads or receiving external MIDI notes. When the
screen is first displayed, it contains the word ALL (edit
all notes) and the text (Hit pads) to the right. When
a pad is pressed, the pad’s currently assigned note
number appears in the field, followed by the pad number
and currently-assigned sound name. On the right side of
the line is the text ( 1 pad ) indicating that one pad
is selected for editing:
Notes:36/A02-SNARE_DRUM ( 1 pad )
If another pad is then pressed, its note number, pad
number, and assigned sound are displayed instead, and
the text to the right displays ( 2 pads). This contin-
ues until the user has selected all of the pads he or she
intends to edit.
• The Edit field:
This is a choice field with two options: VELOCITY and DURATION.
It is used to select which of these two parameters will be affected.
• The Do field:
This is a choice field with four options:
1. ADD VALUE: This selection adds the number in the
Value field to the velocity or duration of each note that
has been selected for editing.
2. SUB VALUE: This selection subtracts the number in the
Value field from the velocity or duration of each note
that has been selected for editing.
3. MULT VAL %: This selection multiplies the velocity or
duration of each note that has been selected for editing by
the number in the Value field. A value of 100% = no
change; values of 101 to 200% proportionally increase
each note’s velocity or duration value; values of 0 to 99%
proportionally decrease each note’s velocity or duration
value.
4. SET TO VAL: This selection changes the velocity or
duration of each note that has been selected for editing to
the number in the Value field.

• The Value field:
This field works in conjunction with the Do field and sets the
number that will be used to change the velocities or durations.
• The <Do it> soft key:
Pressing this soft key performs the edit specified in the above fields.
Editing Note Number Assignment of Drum Note Events
This feature affects Drum tracks only. It is used to change all notes
of one drum to that of another drum. It does this by searching for all
drum notes of the specified note number and changing them to
another note number assignment. To change the note number
assignment of a group of notes, select 2 (Edit note number
assignment) from the Edit Note Data menu; the following screen
will appear:

===== Edit Note Number Assignment ======
Seqnc: 1-Seqnc_name
Track: 1-Track_name
Ticks:001.01.00-001.01.00
Change notes:64/A01-Sound_name
To notes:65/A07-Sound_name
========================================
<Do it>

The fields and soft keys are:
• The Seqnc field:
This specifies the sequence to be edited.
• The Track field:
This specifies the track to be edited. Only one track can be edited at
a time. Since this function only works on Drum tracks, if a MIDI
track is selected the message “You must select a drums track” will
appear.
• The Ticks fields:
These two bar.beat.tick fields are used to determine the region
within the track that will be edited. The leftmost field sets the start
of the region and the rightmost field holds a location that is one tick
after the region to be edited.
• The Change notes field:
This field is used to determine which drum notes will be affected.
While the cursor is in this field, press the pad of the drum notes to
be changed—its currently assigned note number and sound will
appear in the field. (You can also send a Note On message to the
MIDI input or enter the note number directly.) Only drum notes
assigned to this note number will be changed.

• The To notes field:
This field determines the note number to which the selected drum
notes will be reassigned. While the cursor is in this field, press the
pad of the drum note to be changed to—its currently assigned note
number and sound will appear in the field. (You can also send a
Note On message to the MIDI input or enter the note number
directly.)
• The <Do fields.
it> soft key:
Pressing this soft key performs the edit as specified in the above
Editing Note Variation Data of Drum Note Events
This feature affects Drum tracks only and is used to edit the Note
Variation data of many drum notes in one operation. Select 3 (Edit
note variation data) from the Edit Note Data menu. The
following screen will appear:

======= Edit Note Variation Data =======
Seqnc: 1-Seqnc_name
Track: 1-Track_name
Ticks:001.01.00-003.01.00
Notes:ALL (Hit pads)
Set notes to param:TUNING & Value: 0
========================================
<Do it>

The fields and soft keys are:
• The Seqnc field:
This specifies the sequence to be edited.
• The Track field:
This specifies the track to be edited. Only one track can be edited at
a time. Since this function works only on Drum tracks, if a MIDI
track is selected the message “You must select a drums track” will
appear.
• The Ticks fields:
These two bar.beat.tick fields are used to determine the region
within the track that will be edited. The leftmost field sets the start
of the region and the rightmost field holds a location that is one tick
after the region to be edited.

• The Notes field:
This field determines which notes will be affected. It cannot be
accessed by the cursor. It can only be changed by pressing pads or
receiving external MIDI notes. When the screen is first displayed, it
appears as shown above with the word ALL (affect all notes) and the
text (Hit pads) to the right. When a pad is pressed, the pad’s
currently assigned note number appears in the field, followed by the
pad number and currently assigned sound name. On the right side
of the line is the text ( 1 pad ) indicating that one pad is se-
lected for editing:
Notes:36/A02-SNARE_DRUM ( 1 pad )
If another pad is then pressed, its note number, pad number, and
assigned sound are displayed instead, and the text to the right
displays ( 2 pads). This continues until the user has selected all
of the pads he or she intends to edit.
• The Set notes to param field:
This choice field determines to which parameter (TUNING, AT-
TACK, DECAY, or FILTER) the selected notes’ Note Variation
parameter will be set.
• The Value field:
This field selects what value of tuning, attack, decay, or filter the
selected notes’ Note Variation data will be set to.
• The <Do it> soft key:
Pressing this key performs the edit as specified in the above fields.

### The STEP EDIT Key
The Step Edit function allows the contents of the active track to be
edited in precise detail. When the Step Edit key is pressed, any
notes or events that exist in the active track at the current sequence
position are displayed on the screen as a series of data fields, which
can then be edited. Also, any notes played at this time are recorded
into the active track at the current sequence position.
To enter step edit mode, press the STEP EDIT key. The following
screen will appear, displaying any notes or events that exist in the
active track at the current sequence position:

============== Step Edit ===============
>N:64/A01-Sound_na V:127 Tun:-120 D: 96
Program_change Val:127
Pitch_bend Val:+ 0
Channel_pressure Val:127
Control:C1-MODULATION_WHEEL Val:127
===== Now:001.01.00 (00:00:00:00) ======
<Insert> <Delete> <PlayEvent> <Options>

A description of the fields and soft keys follows:
• The event display area (lines 2 through 6 of the LCD
screen).
This area of the screen displays up to five events, one per line, that
exist in the active track at the sequence location displayed in the
Now field. These events are most commonly notes (either drum or
keyboard notes, depending on whether the active track is a Drum
track or a MIDI track), but they can also be one of a number of
special MIDI message types. The format of each of the various event
types is described in detail later in this chapter, in the “Step Edit
Event Types” section. The event positioned at the uppermost line
(preceded by the >) is called the active event. It is the only event
whose fields can be edited by the cursor.
• The Now field:
The field shows the current position within the sequence. As in the
Play/Record screen, this value is changed by using the REWIND,
FAST FORWARD, and LOCATE keys. As this value changes, the
event display area is continually updated to display the events
contained at the newly-displayed location.

• SOFT KEY 1 (<Insert> or <Paste>):
This soft key has one of two functions, depending on the current
setting of the Function of soft key 1&2 field in the Step
Edit Options screen (described below):
1. <Insert>: When pressed, a new event is inserted at the
current sequence position. The type of event inserted is
determined by the Event to insert field in the Step
Edit Options screen.
2. <Paste>: Pressing this key inserts a copy of the event
last removed from the track by using the <Cut> soft key.
If the <Cut> soft key has not been used since turning
the power on, nothing will be inserted.
• SOFT KEY 2 (<Delete> or <Cut>):
This soft key has one of two functions, depending on the current
setting of the Function of soft key 1&2 field in the Step
Edit Options screen:
1. <Delete>: When pressed, the active event is deleted
from the screen. The active event is the event at the
uppermost line of the screen (preceded by the >).
2. <Cut>: When pressed, the active event is deleted from
the screen and saved internally. If the <Paste> soft key
is then pressed, a copy of that stored event will be in-
serted into the screen.
• SOFT KEY 3 (<PlayEvent>):
Pressing this soft key causes the active event to be played. The
active event is the event at the uppermost line of the screen (pre-
ceded by the >).
• SOFT KEY 4 (<Options>):
Pressing this soft key causes the Step Edit Options screen, de-
scribed later in this chapter, to appear.
Using Step Edit
To use Step Edit to edit recorded events:
1. Press STEP EDIT. The Now field will change to the
nearest step. A step is defined as a specific note timing
value, 1/8 notes through 1/32 triplets, set in the Note
value field in the Timing Correct screen. Any notes or
other MIDI events existing in the active track at that
location will be displayed on the screen.
2. Use the REWIND, FAST FORWARD, or LOCATE keys to
find the desired location within the sequence. As in the
Play/Record screen, the [<<] and [>>] keys move to the
previous or next bar boundary and the [<] and [>] keys

move to the previous or next step within the active track.
(It is also possible to change the function of the [<] and
[>] keys to search forward or backward to the next event
within the track. This option is selected in the Step Edit
Options screen.)
3. You can now edit any of the data fields for any of the
displayed events by moving the cursor to the desired field
and editing it. Also, any notes played from the pads or
external MIDI keyboard at this time will be recorded into
this location and immediately displayed on the screen.
4. To view other locations within the sequence, use the
REWIND, FAST FORWARD, and LOCATE keys.
5. Once you’re finished editing, press MAIN SCREEN to
return to the Play/Record screen.
Of the five on-screen events, only the uppermost line can be edited.
It is edited by moving the cursor to the desired field within the line
and editing the field contents. This uppermost line is called the
active event, and is preceded by a >. To edit an event, it must be
moved up to the active event line using the CURSOR UP and
CURSOR DOWN keys.
Use the [<] or [>] key to move to the previous or next step within the
active track, and the [<<] or [>>] key to move to the previous or next
bar boundary.
As you move through the sequence, any events in the active track at
that position will be displayed on the screen, and any events (on all
tracks) at the current position will be played (output through MIDI),
just as if the sequence had been played at that position only. If you
don’t want to hear a particular track, turn that track OFF in the
Play/Record screen; if you want to hear only the active track, turn
solo mode to ON in the Play/Record screen. To edit any of the fields
in the active event (uppermost line), move the cursor left or right to
the desired field and change the contents as desired. If there are
multiple events at that step, they will be displayed on the other on-
screen event lines. Use the CURSOR UP or CURSOR DOWN keys
to access different events by scrolling the screen’s five-line window
UP or DOWN, thereby moving higher- or lower-numbered events to
the active event line.
COMMENT: All mid-sequence control messages, including
the 128 Controllers, Pitch Bend, Program Change, Mixer
Volume, Mixer Pan, and Individual Out/Effects Level, only
take effect after being played in a sequence. This means that
if you play a section of a sequence that contains a specific
controller event, the last played value of that controller will
remain active until another occurrence of the same controller
is played—even if you stop the sequence and start playing it
from another location. Because of this, whenever you use one
of these events within a sequence, it is important to insert

another event of the same type at the beginning of the se-
quence to set the controller to an initial value.
Step Edit Event Types
The Step Edit screen can display up to five events, one on each line,
that exist in the active track at the current Now field position. The
format of the event line is different for each type of event. The
following is a description of each event type:
• The Drum Note event
>N:64/A01-My_Sound V:127 Tun:-120 D: 96
The fields are:
1. The Note Number field (N:64 64 64 64 64/A01-My_Sound):
This is the note number assignment (35-98) of the drum
note event.
2. The Pad Number field (N:64/A01 A01 A01 A01 A01-My_Sound):
This is the pad number (A01-D16) that is currently
assigned to the note number displayed to the left. This
field is for display only and cannot be edited.
3. The Sound Name field (N:64/A01-My_Sound My_Sound My_Sound My_Sound My_Sound):
This field shows the first eight characters of the sound
name currently assigned (in the active program) to the
note number selected to the left. This field is for display
only and cannot be edited.
4. The Velocity field (V:127 127 127 127 127):
This is the velocity of the drum note.
5. The Note Variation Parameter field (Tun Tun Tun Tun Tun:-120):
Each drum note contains Note Variation data, a unique
value of either tuning, attack, decay, or filter frequency,
for that note only. This field determines which of those
four parameters is contained in this note, and therefore
which of those four sound parameters will be affected
when this note plays. There are four options: TUN (tun-
ing), DCY (decay), ATK (attack) or FLT (filter frequency).
6. The Note Variation Data field (Tun:-120 -120 -120 -120 -120):
This field works in conjunction with the Note Variation
Parameter field to the left. It contains the data for the
parameter selected in that field. If the parameter is set to
TUN, the range is -120 to 120 tenths of a semitone. When
set to either ATK or DCY, the range is from 0 to 5000
milliseconds. When set to FLT, the range is 0 to 100.

7. The Duration field (D: 96 96 96 96 96):
This field shows the note duration in ticks (96 ticks = one
quarter note). The range is 1-9999 ticks.
• The MIDI Note event
>Note: 60(C.3 ) V:127 ^V: 64 D: 96
The fields are:
1. The Note Number field (Note: 60 60 60 60 60(C.3 ):
This is the MIDI note number (0-127) of the note, indicat-
ing the pitch.
2. The Note Name field (Note: 60(C.3 C.3 C.3 C.3 C.3 )):
This field shows the note name (C-2 to G8) for the note
number shown to the left.
3. The Velocity field (V:127 127 127 127 127):
This is the Note On velocity of the note.
4. The Release Velocity field (^V: 64 64 64 64 64):
This is the release velocity of the note.
5. The Duration field (D: 96 96 96 96 96):
This field shows the note duration in ticks (96 ticks = one
quarter note). The range is 1-9999 ticks.
• The Program Change event
>Program_change Val: 1
The single field, Val, with a range of 1-128, is used to select the
MIDI program number.
• The Pitch Bend event
>Pitch_bend Val:+ 0
The single field, Val, contains the actual numeric value of the pitch
bend event. It is a signed field, with a range from -8192 to 8191.
• The Channel Pressure event
>Channel_pressure Val:127
The single field, Val, has a range of 0-127.

• The Poly Pressure event
>Poly_pressure Note: 60(C.3 ) Val:127
There are three fields:
1. The Note Number field (Note: 60 60 60 60 60(C.3 )):
This is the note to which the pressure message applies.
2. The Note Name field (Note: 60<C.3 C.3 C.3 C.3 C.3 )):
This is the note name for the note number selected at the
left. This is for display only and cannot be edited.
3. The Value field (Val:127 127 127 127 127):
This is the pressure value for the selected note number (0
to 127).
• The System-Exclusive event
>System_exc Size: 1 Byte: 1 Val: 0
There are three fields:
1. The Size field:
This displays the total number of data bytes. The maxi-
mum size of a system-exclusive event in the sequencer is
999 bytes.
2. The Byte field:
The number of the byte whose contents are currently
displayed in the Val field.
3. The Val field:
The current value of the byte number displayed in the
Byte field.
• The Stereo Volume event
>Stereo_volume Pad:A01 Val:100
This message is exclusive to the sequencer and is used to change the
Stereo Mixer Volume setting of a particular sound in mid-sequence.
When the Record Live Changes feature is used (accessed by pressing
MIXER/EFFECTS, then 4), many of these events are recorded into
the active track to simulate a smooth and continuous mixer volume
change. There are two fields:
1. The Pad field:
This field determines which of the 64 pad numbers/mixer
sliders (A01-D16) this message will affect.
2. The Val field:
This field contains the actual mixer slider value (0-100).

• The Stereo Pan event
>Stereo_pan Pad:A01 Val:C
This message is exclusive to the sequencer and is used to change the
stereo mixer pan setting of a particular sound in mid-sequence.
When the Record Live Changes feature is used (accessed by pressing
MIXER/EFFECTS, then 4), many of these events are recorded into
the active track to simulate a smooth and continuous mixer pan
change. There are two fields:
1. The Pad field:
This field determines which of the 64 pad numbers/pan
pots (A01-D16) this message will affect.
2. The Val field:
This field contains the actual pan pot value (50L - C -
50R).
• The Output/Effect Volume event
>Output/effect_volume Pad:A01 Val:127
This message is exclusive to the sequencer and is used to change the
individual output/effects mixer volume setting of a particular sound
in mid-sequence. When the Record Live Changes feature is used
(accessed by pressing MIXER/EFFECTS, then 4), many of these
events are recorded into the active track to simulate a smooth and
continuous individual output/effects mixer volume change. There
are two fields:
1. The Pad field:
This field determines which of the 64 pad numbers/mixer
sliders (A01-D16) this message affects.
2. The Val field:
This field contains the actual mixer slider value (0-100).
• The Control Change event
>Control:C1-MODULATION WHEEL Val:127
There are two fields:
1. The Control field (Control:C1-MODULATION C1-MODULATION C1-MODULATION C1-MODULATION C1-MODULATION
WHEEL WHEEL WHEEL WHEEL WHEEL):
There are 128 MIDI continuous controllers (0-127), each
with an assigned control function. The control function,
as defined in the MIDI 1.0 Detailed Specification, is
displayed to the right of the selected controller number.

2. The Val field (Val:127 127 127 127 127):
This field contains the data value of the displayed con-
troller event.
• The Tune Request event
>Tune request
This event type has no data fields.
Step Edit Options
Pressing the <Options> soft key in the Step Edit screen displays
the following screen:
=========== Step Edit Options ==========
Event to insert:NOTES
Auto step increment on key release:NO
Duration of recorded notes:AS PLAYED
Function of soft key 1&2:PASTE/CUT
Function of '<' and '>' keys:NEXT EVENT
======= Step Edit Display Filter =======
View:ALL EVENTS
This screen presents a number of options related to use of the Step
Edit function:
• The Event to insert field:
This parameter selects which type of MIDI event will be inserted
when the <Insert> soft key from the Step Edit screen is pressed.
The options include all the available MIDI event types and 128
MIDI controllers. If one of these controllers is selected, the name
assigned to that controller number is also displayed.
• The Auto step increment on key release field:
If set to YES, the Step Edit screen’s Now field will automatically
move forward one step (as defined by the timing value set in the
Note Value field of the Timing Correct screen) after each key
from the MIDI keyboard is released or, if a chord was played, after
the last key from the chord is released. (If the active track is a Drum
track, the Now field will increment after a pad is released.) This
allows, for example, the recording of a series of notes or chords, one
on each step, without having to advance manually to the next step
after playing each key. If this field is set to NO, this function is
defeated.

• The Duration of recorded notes field:
This field is used while in Step Edit mode to determine the method
by which durations are assigned to notes recorded from a MIDI
keyboard or the sequencer pads. This is a choice field and has two
options: SAME AS STEP and AS PLAYED:
1. If set to SAME AS STEP, durations are always four ticks
less than the current step size (the current Note
Value field setting in the Timing Correct screen).
2. If set to AS PLAYED, the actual time the note is held
(relative to the current tempo) is used for the duration
value, even though the sequence is not playing. To guide
your timing, if a key is held down longer than one 1/4-
note, a metronome click plays exactly one 1/4-note after
the key is depressed, and sounds again for each addi-
tional 1/4-note the key is held down. For example, if you
wanted to record a note with a duration of one 1/2-note,
you would play the key and release it after two metro-
nome clicks were heard.
• The Function of soft key 1&2 field:
This choice field is used to determine the functions of soft keys 1
and 2. It has two options:
1. INSERT/DELETE:
The functions of soft keys 1 and 2 are <Insert> and
<Delete>. <Insert> causes an event to be inserted
onto the screen. The type of event is determined by the
setting of the Event to insert field above. <De-
lete> removes the active event from the screen.
2. PASTE/CUT.
The functions of soft keys 1 and 2 are <Paste> and
<Cut>. <Cut> deletes the active event from the screen
and saves a copy of it internally. <Paste> inserts onto
the screen a copy of the event most recently cut.
• The Function of '<' And '>' keys field:
This choice field is used to determine the function of the REWIND
[<] and FAST FORWARD [>] keys. It has two options:
1. NEXT STEP:
This is the default setting. Pressing the REWIND [<] key
moves to the previous step within the sequence. Pressing
the FAST FORWARD [>] key moves to the next step
within the sequence. (The timing value of a step is set in
the Timing Correct screen’s Note Value field.)
COMMENT: If the current setting of the Swing%
field is set to a value other than 50%, pressing the
REWIND [<] and FAST FORARD [>] keys will
move forward or backward to locations that fall
on swing timing intervals. If you are editing a
sequence that contains 1/16-notes recorded at a
swing setting of 50%, the even-numbered


1/16-notes will NOT be heard as you step through
the sequence, because only notes existing in swung
1/16-note locations will be viewed. This same rule
applies to the Shift Timing function: if the Shift
Amount field is set to 0 and you are editing a
sequence that was recorded while it was set to any
amount other than 0, none of the notes will be seen
as you step through the sequence, because these
notes fall on shifted locations, and you are cur-
rently viewing only those notes that fall on non-
shifted locations.
2. NEXT EVENT:
Pressing the REWIND [<] key searches to the previous
event within the track. Pressing the FAST FORWARD [>]
key searches to the next event within the track. To search
for specific event types, set the Step Edit Display Filter to
the desired event type; pressing these keys will then
cause the sequencer to locate to the next or previous
event of the specified type, ignoring event types not
included in the display filter settings.
• The Step Edit Display Filter section.
This is similar to the erase filter or the MIDI input filter, except this
one controls which types of MIDI events are displayed in the Step
Edit screen. For example, if the only events you want to edit are
pitch bend messages, it is bothersome to view all the other events.
Another use is to filter out continuous controller data to make it
easier to view only the note events.
To use the display filter, move the cursor to the View field. This is a
choice field with three options:
1. ALL EVENTS: If this option is selected, all possible event
types will be displayed.
2. ONLY VIEW: If this option is selected, only one event
type can be displayed, and the type of event to be dis-
played is selected in a new field appearing directly to the
right on the same line. In this rightmost field all event
types are listed, including all 128 MIDI controllers, each
one individually named as listed in the MIDI 1.0 Detailed
Specification.
3. ALL EXCEPT: This option is similar to ONLY detailed above, except that all event types except the
event displayed to the right of the words ALL VIEW,
EXCEPT
are displayed.


Step Recording
Step Edit also makes it possible to record new notes from a MIDI
keyboard while the sequence is not playing. To record a note while
in Step Edit mode, move to the desired position within the sequence,
then play and release the desired note on the MIDI keyboard. This
note will then appear as the new active event, with its pitch, veloc-
ity, release velocity, and duration displayed numerically. The dura-
tion of the note is taken from the actual duration played, relative to
the current tempo. However, if the Duration of recorded
notes field in the Step Edit Options screen is set to SAME AS
STEP, The duration always defaults to the current step value.
If the Auto step increment on key release field in the
Step Edit Options screen is set to YES, the current position within
the sequence will automatically advance one step forward when the
newly recorded note (or chord) is released. This allow you to, for
example, record a series of notes (or chords) one at a time while
stopped, and automatically play them back with evenly spaced
timing. To do this:
1. Set up your sequence and track for recording from your
MIDI keyboard as you would to record in real time.
2. In the Timing Correct screen, set the Note value field
to the desired step value.
3. Rewind to the start of the sequence.
4. Press STEP EDIT.
5. Press SOFT KEY 4, <Options>.
6. Set the Auto step increment on key release
field to YES.
7. Press STEP EDIT again.
8. Play a series of notes (or chords), one at a time.
9. Press PLAY START. The notes you have just entered will
play back with evenly spaced timing.


### The EDIT LOOP Key
This function allows a specified number of bars within a sequence to
repeat in a loop while playing or overdubbing. This allows for quick
recording or editing of the looped section. Press EDIT LOOP and the
following screen will be displayed:

============== Edit Loop ===============
Number of Bars:2 1st bar:54
========================================
<Turn On>

The screen fields and soft keys are:
• The Number of bars field:
This field specifies the number of bars that will be looped when the
edit loop is turned on.
• The 1st bar field:
This field specifies the starting bar of the edit loop. The current bar
number is automatically inserted here.
• The <Turn on> soft key:
Pressing this soft key turns the edit loop on. It also causes the Play/
Record screen to be displayed and the Edit Loop light to go on,
indicating that an edit loop is active.
If EDIT LOOP is again pressed while an edit loop is active, the
same screen will appear, but with two changes:
1. The first two fields are displayed, but all changes are locked out.
2. The bottom line changes to:
<Turn Off> <Undo & off>
If SOFT KEY 1, <Turn off>, is pressed at this time, the edit loop
will be turned off, returning the sequence to its normal operation.
However, if SOFT KEY 2, <Undo & off>, is pressed, the loop is
turned off, but all changes made while the loop was on are not used
and the sequence returns to its status before the loop was turned on.
In either case, the Edit Loop light is turned off and the display
returns to the Play/Record screen.


Using Edit Loop as an Undo Function
Because the Edit Loop function allows you the option of ignoring all
recording and editing that was done while Edit Loop was on, it
serves very well as an undo function.
For example, if you want to record a drum fill on bar 4 of a 4-bar
sequence, but you aren’t sure if you want to keep it, following these
steps will allow you to try the fill, then restore the sequence to its
original state if you don’t like it:
1. Fast forward to bar 4.
2. Press EDIT LOOP.
3. Set the Number of bars field to 1.
4. Press SOFT KEY 1, <Turn on>, which will turn the
Edit Loop on. Bar 4 will now repeatedly play in a loop.
5. Overdub your drum fill.
6. Press EDIT LOOP again.
7. If you didn’t like how the fill sounded, press SOFT KEY 2,
<Undo & off>, and the sequence will return to its
original state. If you want to keep the fill, press SOFT
KEY 1 (<Turn off>) and the sequence will now
contain the new drum fill.


### The TRANSPOSE Key
This function allows you to transpose a track up or down by a
specified amount in real time. This function is only a temporary
change—the sequence data are not altered unless SOFT KEY 1,
<Transpose Permanent>, is pressed. Also, the sequencer does
not transpose Drum tracks—only MIDI tracks can be transposed.
(Though if you do want to transpose a Drum track, temporarily
changing its type to MIDI on the Play/Record screen will allow you
to transpose it. Make sure to change it back to DRUM when you’re
done.) Pressing TRANSPOSE causes the following screen to appear:

============== Transpose ===============
Track: 0-(all tracks) Amount: 0
(Play synth key to set amount)
========== Transpose Permanent =========
Ticks:001.01.00-003.01.00
========================================
<Transpose Permanent>

The following is a description of each of the screen fields and soft
keys:
• The Track field:
The field specifies the track that will be transposed. Enter a 0 here
if you want all tracks (except Drum tracks) to be transposed simul-
taneously.
• The Amount field:
This field sets the amount and direction of transposition in semi-
tones. For example, to transpose up a fifth, enter a 7. To transpose
down a fourth, turn the data entry control to the left until -5
appears. A much faster way to set this field is to simply press a key
on the MIDI keyboard—the amount will be automatically set by the
location of the key in relation to Middle C. For example, pressing a
key one octave below Middle C would set the Amount field to -12.
If the Amount field is set to any value other than 0, the transpose
light will go on, indicating that the transpose function is active. It
will turn off when this field is returned to 0, or if <Transpose
Permanent> is selected.
• The Ticks fields:
These two bar.beat.tick fields specify the region to be permanently
transposed when the <Transpose Permanent> soft key is
pressed. The first field (before the dash) sets the start of the region


and the second field sets a location one tick after the last tick of the
region to be transposed.
• The <Transpose Permanent> soft key:
Pressing this soft key causes the above-specified transposition to be
made permanent by actually changing each of the note events
within the specified region of the sequence. After this operation, the
Amount field is reset to 0 and the transpose light goes off.
Transposing in Real Time While Playing
To transpose a sequence in real time while playing, follow these
steps:
1. Play the sequence.
2. Press the TRANSPOSE key.
3. Locate Middle C on the keyboard. Pressing any key above Middle
C will instantly transpose the sequence up by an amount equal to
the interval between the new key and Middle C. Pressing any key
below Middle C will instantly transpose the sequence down by an
amount equal to the interval between the new key and Middle C.
When you press the transposition key, it will only be used to set
the transposition interval—the note itself will not sound. Be sure
to press the key immediately before the instant that you want
the transposition to occur. To remind you that your sequence is
being transposed, the light above the TRANSPOSE key will go on
if any Amount value other than 0 has been selected.
4. To return to the original key signature, press Middle C or set the
Amount field to 0.


---

## ### Overview
One way to create a song in the sequencer is to record all of the
parts in one long sequence, either playing the entire song manually
or using the copy functions to duplicate repeating sections. Another
way is use Song mode. In Song mode, several sequences are
entered into a list, with each sequence being a different section of
the whole song. Once the entire list is entered, Song mode automati-
cally plays the list of sequences in the order they were entered. This
is especially useful in creating arrangements that have many
repeating sections, such as drum parts. Song mode has the following
advantages over using a long sequence to record a song:
• The song structure can be created very quickly.
• The content of the sections of the song can be changed very
quickly.
A song in the sequencer consists of up to 250 steps, each of which
contains the number of the sequence that will play at the step and
the number of times the step will repeat before going on to the next
step in the song. After the last step, the song can either stop playing
or loop back to an earlier step. The sequencer can hold up to 20
songs in memory at one time. Recording is not permitted in Song
mode. Rather, the individual sequences must be recorded or edited
while in Play/Record mode.

### The SONG Key and Song Mode Screen

To enter Song mode, press the SONG key. The Song Mode screen
will appear:

```
=============== Song mode ==============
Song: 1-(unused) Loop:TO STEP 1
Song starts at SMPTE#:00:00:00:00.00
========= Contents of step: 1 =========
Sqnc: 1-(unused) Reps(0=end): 1
Bars: 0 Tempo:120.0 BPM
===== Now:001.01.00 (00:00:00:00) ======
<Ins/Del> <Conv2Seq> <Step-1> <Step+1>
```

While this screen is showing, the sequencer is in Song mode, mean-
ing that if play is entered, the active song will play instead of the
active sequence.
All of the Play/Record keys except RECORD and OVERDUB operate
on the active song. PLAY START plays the active song from the
start; PLAY plays the active song from the current location in the
Now field; the REWIND, FAST FORWARD, and LOCATE keys
change the position within the song.
A detailed description of each of the on-screen fields and soft keys is
given below:
• The Song field:
This field selects the current song number (1-20). There are 20
songs, each containing its own list of 250 steps.
• The Song Name field (Song: 1-(unused) (unused) (unused) (unused) (unused)):
This field has no title but exists directly to the right of the song
number. It is the 16-character name of the active song. Changing
the song name is done in the same manner as changing the se-
quence name in the Play/Record screen.
• The Loop field:
This field indicates what will occur when the current song plays all
the way to its end. There are two options:
1. OFF: The song stops playing.
2. TO STEP 1: The song loops back to the step number
shown directly to the right of the word STEP. This step
number can be changed by moving the cursor to it and
changing it.


• The SMPTE start field:
This five-part field sets the SMPTE number associated with the
exact beginning of the song. Also called SMPTE offset, this is the
SMPTE number which, when the sequencer is syncing to SMPTE,
denotes the beginning of the song. Normally, this is set to all zeroes
(00:00:00:00.00). The five parts are Hours:Minutes:Seconds:
Frames.HundrethFrames.
• The Contents of step field:
This shows the current step number (1-250) within the active song.
The data displayed below this field are the data contained within
this step.
• The Sqnc field:
This field indicates the sequence number contained in the current
step. The selected sequence’s name is displayed to the right.
• The Reps(0=end) field:
This field indicates the number of repetitions that the sequence in
the current step will play before moving on to the next step. For
example, if you want the sequence to play only once in the current
step, a 1 should be entered here. If a 0 is entered here, the sequencer
will treat this step as the end of the song, and either stop playing or
loop to a previous step number, depending on the setting of the
Loop field.
• The Bars field:
This field shows the total number of bars in the selected sequence. It
is for display only and can’t be edited.
• The Tempo field:
This field shows the sequence tempo (the tempo value stored within
the sequence—not the master tempo) of the selected sequence.
• The Now field:
This has nearly the same function as in the Play/Record screen,
except that in Song mode this number refers to the current position
within the song, not within the sequence.
• The <Ins/Del> soft key:
This key is used for inserting a new step into a song, deleting a step,
or deleting an entire song. Pressing it causes the following screen to
appear:


=== Insert Step === === Delete Step ===
Ins before step: 1 Delete step: 1
(This and all higher (This step will be
steps will be moved deleted and all
up and a new step higher steps will
will be inserted.) be moved down.
=================== ===================
<Insert> <Delete><Del song!>

To insert a new step into the song, enter the step number before
which the new step will be inserted in the Ins before step
field, then press <Insert>. The Song screen will be redisplayed
and a new step inserted, with all higher-numbered steps moved up
by one position.
To delete a step, select the step number to be deleted in the Delete
step field and press <Delete>. The Song screen will be
redisplayed and the specified step deleted, with all higher-numbered
steps moved down by one position.
To delete all steps in the song or to delete all songs, press <Del
song!> and follow the instructions on the screens that appear.
Other soft keys on the Song screen:
• The <Conv2Seq> soft key:
This key accesses a feature that converts the individual steps in a
song into one long sequence. It does this by copying each event in all
of the sequences within the song to a new sequence that has the
same total number of bars as the song. This function is described in
detail later in this chapter.
• The <Step-1> soft key:
Pressing this soft key decrements the Contents of step field.
• The <Step+1> soft key:
Pressing this soft key increments the Contents of step field.


An Example of Creating and Playing a Song
The following demonstrates how to use Song mode to create a song
on the sequencer:
1. Record some drum or MIDI data into sequences 1, 2, and 3.
2. Enter Song mode by pressing the SONG key.
3. In the Song field, select an unused song number. An unused song
is indicated as (unused) in the Song Name field.
4. Set the Contents step to step number1.
of step field to 1, which sets the active
5. Select 1 in the Sqnc field, indicating that you want sequence
number 1 to play at the start of the song.
6. Select 2 in the Reps field, indicating that you want sequence
number 1 to repeat two times before completing step 1.
7. Press <Step+1> to move on to step 2.
8. Select 2 in the Sqnc field and 1 in the Reps field, indicating that
you want sequence 2 to play only once for step 2.
9. Press <Step+1> to move on to step 3.
10. Select 3 in the Sqnc field and 2 in the Reps field, indicating
that you want sequence 3 to play twice for step 3.
11. Press <Step+1> to move on to step 4.
12. Select 0 in the Reps field, indicating that this is the end of your
song. If a 0 already exists here, there is no need to enter it again.
13. Select the TO STEP option in the Loop field and enter a 2 to
the right of the word STEP, indicating that you want the song to
loop back to step 2 once it reaches its end.
14. Press PLAY START. The song will play back as follows:
First, it will play two repetitions of sequence 1;
next, it will play one repetition of sequence 2;
next, it will play two repetitions of sequence 3;
after that, it will repeat steps 2 and 3 indefinitely.
Notice that the Now field always indicates the position within the
song, not the position within each sequence.


COMMENT: Occasionally you may see the message Ana-
lyzing sequence. Please wait... on the lowest
line of the screen, asking that you wait briefly while the
sequencer does some thinking. This occurs after you make
changes in the song, but only if the song contains a large
number of different sequences. Once this process is done, all
subsequent fast-forward, rewind, and locate operations will
be immediate.
COMMENT: If you notice a timing irregularity in your song
at the point of transition from one sequence to another, the
problem may be due to the assignments of the Pgm field (in
the Play/Record screen) for the sequence that plays immedi-
ately after the timing irregularity. If a sequence containing
these program assignments is played in Song mode (or if the
sequence is selected manually while the sequencer is play-
ing), the sequence’s program assignments are sent out at the
moment that the sequence starts to play in the song. This can
present a problem, because most synthesizers require time to
change programs, which can cause any notes existing at the
start of the new sequence to be delayed. This delay is brief in
most synthesizers, but is usually enough to cause a timing
irregularity when it occurs at the start of a sequence. To
avoid this problem, don’t assign program changes to se-
quences that you are using in Song mode. If you need to use
program changes within the song, make sure that no notes
exist at the start of the sequences that contain the program
changes. Another alternative is to insert MIDI Program
Change commands within the sequences in the song at
locations where no notes exist.


Converting a Song Into a Long Sequence
Song mode is useful for quickly creating the format of a song.
However, it is cumbersome compared to Sequence mode when fine-
tuning the details of a complex song. It is therefore useful to create
a song initially using Song mode, then convert that song into a long
sequence. This allows you to use the more versatile sequence editing
features to complete the song. The Convert Song to Sequence
function does this conversion. All sequences in the song, including
their designated repetitions, are copied end-to-end into the specified
sequence. Note that track names, track status (Drum or MIDI),
MIDI output channel assignments, MIDI program change assign-
ments, stereo mixer settings, effects mixer settings, tuning settings,
and tempo settings for the newly created sequence are taken from
the first sequence in the song, and that the song’s loop status is
used for the new sequence’s loop status. To use this function, select
the <Conv2Seq>) soft key from the Song screen. The following
screen will appear:

======= Convert Song To Sequence =======
Convert from song: 1-Song_name
To sequence: 1-Sequence_name
(The existing contents of the
destination sequence will be erased!)
========================================
<Do it>

The fields are:
• The Convert from song field:
This is the number of the song that will be converted into a se-
quence. The song’s name is shown to the right.
• The To sequence field:
This is the number of the sequence that will contain the converted
song. The sequence’s name is shown to the right. Any data in this
sequence will be replaced.
• The <Do it> soft key:
Pressing this soft key performs the copy as specified.
COMMENT: Be sure that the drum or MIDI status of like-
numbered tracks of the sequences in a song match. If not,
drum track data can be appended onto the end of a MIDI
track or vice versa. This would cause keyboard notes to play
drum sounds , or drum notes (in which the note number
indicates drum selection) to play various keyboard pitches.