import React, { useMemo, useState } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ChartContainer, ChartTooltip, ChartTooltipContent, ChartLegend, ChartLegendContent } from '@/components/ui/chart';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, ResponsiveContainer,
} from 'recharts';
import { DownloadIcon, SmartphoneIcon, AppWindowIcon, UsersIcon, TrendingUpIcon } from 'lucide-react';

type Row = { event_type: string; platform: string; device_id: string; created_at: string; app_version: string | null };

const RANGE_OPTIONS = [
  { value: '7', label: '7 Tage' },
  { value: '30', label: '30 Tage' },
  { value: '90', label: '90 Tage' },
];

const TZ = 'Europe/Berlin';

function berlinDateKey(iso: string) {
  // YYYY-MM-DD im Berliner Tag
  const d = new Date(iso);
  return new Intl.DateTimeFormat('en-CA', { timeZone: TZ, year: 'numeric', month: '2-digit', day: '2-digit' }).format(d);
}

function formatDay(key: string) {
  const [y, m, d] = key.split('-');
  return `${d}.${m}.`;
}

const chartConfig = {
  install: { label: 'Installationen', color: 'hsl(var(--primary))' },
  app_open: { label: 'App-Öffnungen', color: 'hsl(var(--chart-2, 217 91% 60%))' },
  devices: { label: 'Aktive Geräte', color: 'hsl(var(--chart-3, 142 76% 36%))' },
  ios: { label: 'iOS', color: 'hsl(var(--chart-1, 220 70% 50%))' },
  android: { label: 'Android', color: 'hsl(var(--chart-2, 142 76% 36%))' },
  web: { label: 'Web', color: 'hsl(var(--chart-3, 280 65% 60%))' },
  unknown: { label: 'Unbekannt', color: 'hsl(var(--muted-foreground))' },
} as const;

const PLATFORM_COLORS: Record<string, string> = {
  ios: 'hsl(220 70% 50%)',
  android: 'hsl(142 76% 36%)',
  web: 'hsl(280 65% 60%)',
  unknown: 'hsl(var(--muted-foreground))',
};

const ReportsPage = () => {
  const [range, setRange] = useState<'7' | '30' | '90'>('30');

  const { data, isLoading } = useQuery({
    queryKey: ['app-analytics-report', range],
    queryFn: async () => {
      const days = parseInt(range, 10);
      const since = new Date();
      since.setDate(since.getDate() - days);
      const all: Row[] = [];
      const pageSize = 1000;
      let from = 0;
      // Paginate to bypass 1000 row limit
      // eslint-disable-next-line no-constant-condition
      while (true) {
        const { data: rows, error } = await supabase
          .from('app_analytics')
          .select('event_type, platform, device_id, created_at, app_version')
          .gte('created_at', since.toISOString())
          .order('created_at', { ascending: true })
          .range(from, from + pageSize - 1);
        if (error) throw error;
        if (!rows || rows.length === 0) break;
        all.push(...(rows as Row[]));
        if (rows.length < pageSize) break;
        from += pageSize;
      }
      return all;
    },
  });

  const stats = useMemo(() => {
    const rows = data ?? [];
    const days = parseInt(range, 10);

    // Build day buckets
    const dayKeys: string[] = [];
    const today = new Date();
    for (let i = days - 1; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(today.getDate() - i);
      dayKeys.push(new Intl.DateTimeFormat('en-CA', { timeZone: TZ, year: 'numeric', month: '2-digit', day: '2-digit' }).format(d));
    }

    const byDay: Record<string, { date: string; install: number; app_open: number; devices: Set<string> }> = {};
    dayKeys.forEach(k => { byDay[k] = { date: k, install: 0, app_open: 0, devices: new Set() }; });

    const platformInstalls: Record<string, Set<string>> = {};
    const versionCounts: Record<string, number> = {};
    const totalDevices = new Set<string>();
    let totalInstalls = 0;
    let totalOpens = 0;

    for (const r of rows) {
      const key = berlinDateKey(r.created_at);
      const bucket = byDay[key];
      if (bucket) {
        if (r.event_type === 'install') bucket.install += 1;
        if (r.event_type === 'app_open') bucket.app_open += 1;
        bucket.devices.add(r.device_id);
      }
      if (r.event_type === 'install') {
        totalInstalls += 1;
        const p = r.platform || 'unknown';
        if (!platformInstalls[p]) platformInstalls[p] = new Set();
        platformInstalls[p].add(r.device_id);
      }
      if (r.event_type === 'app_open') {
        totalOpens += 1;
        const v = r.app_version || 'unbekannt';
        versionCounts[v] = (versionCounts[v] ?? 0) + 1;
      }
      totalDevices.add(r.device_id);
    }

    const daily = dayKeys.map(k => ({
      date: k,
      label: formatDay(k),
      install: byDay[k].install,
      app_open: byDay[k].app_open,
      devices: byDay[k].devices.size,
    }));

    const platforms = Object.entries(platformInstalls).map(([name, set]) => ({
      name,
      value: set.size,
      fill: PLATFORM_COLORS[name] ?? PLATFORM_COLORS.unknown,
    }));

    const versions = Object.entries(versionCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8)
      .map(([name, value]) => ({ name, value }));

    return {
      daily,
      platforms,
      versions,
      totalInstalls,
      totalOpens,
      activeDevices: totalDevices.size,
      avgOpensPerDevice: totalDevices.size ? +(totalOpens / totalDevices.size).toFixed(1) : 0,
    };
  }, [data, range]);

  const exportCsv = () => {
    const headers = ['Datum', 'Installationen', 'App-Öffnungen', 'Aktive Geräte'];
    const lines = [headers.join(',')];
    stats.daily.forEach(d => lines.push([d.date, d.install, d.app_open, d.devices].join(',')));
    const blob = new Blob([lines.join('\n')], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `report-${range}d.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <DashboardLayout title="Berichte">
      <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
        <Tabs value={range} onValueChange={(v) => setRange(v as any)}>
          <TabsList>
            {RANGE_OPTIONS.map(o => (
              <TabsTrigger key={o.value} value={o.value}>{o.label}</TabsTrigger>
            ))}
          </TabsList>
        </Tabs>
        <button
          onClick={exportCsv}
          className="inline-flex items-center gap-2 rounded-md border bg-background px-3 py-1.5 text-sm hover:bg-muted"
        >
          <DownloadIcon className="h-4 w-4" /> CSV exportieren
        </button>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4 mb-6">
        <StatCard title="Installationen" value={stats.totalInstalls} icon={<SmartphoneIcon className="h-5 w-5 text-primary" />} description={`Letzte ${range} Tage`} />
        <StatCard title="App-Öffnungen" value={stats.totalOpens} icon={<AppWindowIcon className="h-5 w-5 text-primary" />} description={`Letzte ${range} Tage`} />
        <StatCard title="Aktive Geräte" value={stats.activeDevices} icon={<UsersIcon className="h-5 w-5 text-primary" />} description="Eindeutige Geräte" />
        <StatCard title="Ø Öffnungen / Gerät" value={stats.avgOpensPerDevice} icon={<TrendingUpIcon className="h-5 w-5 text-primary" />} description="Engagement" />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Installationen & Öffnungen</CardTitle>
            <CardDescription>Tägliche Aktivität (Zeitzone: Europe/Berlin)</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="h-[320px] animate-pulse rounded-md bg-muted" />
            ) : (
              <ChartContainer config={chartConfig as any} className="h-[320px] w-full">
                <AreaChart data={stats.daily} margin={{ left: 4, right: 8, top: 8 }}>
                  <defs>
                    <linearGradient id="fillInstall" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="var(--color-install)" stopOpacity={0.6} />
                      <stop offset="95%" stopColor="var(--color-install)" stopOpacity={0.05} />
                    </linearGradient>
                    <linearGradient id="fillOpen" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="var(--color-app_open)" stopOpacity={0.6} />
                      <stop offset="95%" stopColor="var(--color-app_open)" stopOpacity={0.05} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid vertical={false} strokeDasharray="3 3" />
                  <XAxis dataKey="label" tickLine={false} axisLine={false} minTickGap={24} />
                  <YAxis tickLine={false} axisLine={false} width={32} />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <ChartLegend content={<ChartLegendContent />} />
                  <Area type="monotone" dataKey="app_open" stroke="var(--color-app_open)" fill="url(#fillOpen)" strokeWidth={2} />
                  <Area type="monotone" dataKey="install" stroke="var(--color-install)" fill="url(#fillInstall)" strokeWidth={2} />
                </AreaChart>
              </ChartContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Aktive Geräte pro Tag</CardTitle>
            <CardDescription>Eindeutige Geräte mit Aktivität</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="h-[280px] animate-pulse rounded-md bg-muted" />
            ) : (
              <ChartContainer config={chartConfig as any} className="h-[280px] w-full">
                <BarChart data={stats.daily} margin={{ left: 4, right: 8, top: 8 }}>
                  <CartesianGrid vertical={false} strokeDasharray="3 3" />
                  <XAxis dataKey="label" tickLine={false} axisLine={false} minTickGap={24} />
                  <YAxis tickLine={false} axisLine={false} width={32} />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Bar dataKey="devices" fill="var(--color-devices)" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ChartContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Plattformen</CardTitle>
            <CardDescription>Installationen nach Plattform</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="h-[280px] animate-pulse rounded-md bg-muted" />
            ) : stats.platforms.length === 0 ? (
              <div className="h-[280px] flex items-center justify-center text-sm text-muted-foreground">Keine Daten</div>
            ) : (
              <ResponsiveContainer width="100%" height={280}>
                <PieChart>
                  <Pie data={stats.platforms} dataKey="value" nameKey="name" innerRadius={60} outerRadius={100} paddingAngle={2}>
                    {stats.platforms.map((p) => <Cell key={p.name} fill={p.fill} />)}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
            )}
            {!isLoading && stats.platforms.length > 0 && (
              <div className="mt-2 flex flex-wrap gap-3 justify-center text-sm">
                {stats.platforms.map(p => (
                  <div key={p.name} className="flex items-center gap-2">
                    <span className="inline-block h-3 w-3 rounded-sm" style={{ background: p.fill }} />
                    <span className="capitalize">{p.name}</span>
                    <span className="text-muted-foreground">{p.value}</span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>App-Versionen</CardTitle>
            <CardDescription>Verteilung der App-Öffnungen nach Version (Top 8)</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="h-[280px] animate-pulse rounded-md bg-muted" />
            ) : stats.versions.length === 0 ? (
              <div className="h-[280px] flex items-center justify-center text-sm text-muted-foreground">Keine Daten</div>
            ) : (
              <ResponsiveContainer width="100%" height={280}>
                <BarChart data={stats.versions} layout="vertical" margin={{ left: 16, right: 16 }}>
                  <CartesianGrid horizontal={false} strokeDasharray="3 3" />
                  <XAxis type="number" tickLine={false} axisLine={false} />
                  <YAxis type="category" dataKey="name" width={90} tickLine={false} axisLine={false} />
                  <Bar dataKey="value" fill="hsl(var(--primary))" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
};

const StatCard = ({ title, value, description, icon }: { title: string; value: number | string; description: string; icon: React.ReactNode }) => (
  <Card>
    <CardHeader className="flex flex-row items-center justify-between pb-2">
      <CardTitle className="text-sm font-medium">{title}</CardTitle>
      {icon}
    </CardHeader>
    <CardContent>
      <div className="text-2xl font-bold">{value}</div>
      <p className="text-xs text-muted-foreground">{description}</p>
    </CardContent>
  </Card>
);

export default ReportsPage;
