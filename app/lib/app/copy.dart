/// Words the app says in its own voice, in one place so tone can be reviewed together.
/// Tone: plain, warm, specific. No exclamation marks, no forced cheer about serious subjects,
/// and never claims more than the app knows ("chosen by rules", not "verified").
library;

String greetingFor(DateTime now) {
  final h = now.toLocal().hour;
  if (h < 5) return 'Good evening';
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

const todayLead = "Today's lead";
const endOfTodayTitle = "You're all caught up.";
const endOfTodayBody = "That's everything we picked for today. Come back tomorrow for more good news.";
const browseMore = 'Browse more in Explore';


const trustBadge = 'No accounts. No ads. No tracking. Everything stays on your phone.';

class WelcomePage {
  const WelcomePage(this.title, this.body);
  final String title;
  final String body;
}

const welcomePages = [
  WelcomePage('A small daily dose of good news', 'Each day you get a short list of stories about progress, solutions and things getting better.'),
  WelcomePage('Chosen openly, never hidden', 'Stories are picked from trusted publishers by published rules. Every story says why it was included, and links to the original.'),
  WelcomePage('Yours, and only yours', 'No accounts, ads or tracking. What you save and hide stays on this device. You can hide anything that does not belong.'),
];
const welcomeStart = "Show me today's news";
const welcomeSkip = 'Skip';
const welcomeNext = 'Next';
