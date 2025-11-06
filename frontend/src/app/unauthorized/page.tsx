import Link from 'next/link';

export default function Unauthorized() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-foreground">403</h1>
        <p className="mt-4 text-xl text-muted-foreground">คุณไม่มีสิทธิ์เข้าถึงหน้านี้</p>
        <Link
          href="/"
          className="mt-6 inline-block px-6 py-3 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors"
        >
          กลับหน้าหลัก
        </Link>
      </div>
    </div>
  );
}
